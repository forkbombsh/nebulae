local socket = require("socket")
local project = require("config.project")

Lmajor, Lminor, Lrevision, Lcodename = love.getVersion()

IsMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

AppName = project.name
AppVersion = project.version

NativeFS = require("lib.nativefs")
assert(NativeFS.getInfo("assets"),
    "\n\nThe assets directory was not found. without it, Nebulae cannot function.\nPlease either reinstall Nebulae or download the assets off the github repo.")

BigFontArial = love.graphics.newFont("assets/fonts/arial/ARIAL.TTF", 24)
MedBigFontArial = love.graphics.newFont("assets/fonts/arial/ARIAL.TTF", 20)
MedFontArial = love.graphics.newFont("assets/fonts/arial/ARIAL.TTF", 15)
BigFontArialBold = love.graphics.newFont("assets/fonts/arial/ARIALBD.TTF", 24)
HugeFontArialBold = love.graphics.newFont("assets/fonts/arial/ARIALBD.TTF", 30)

require("lib.deepcopy")
pprint = require("lib.pprint")
pprint.setup {
    show_all = true,
    wrap_array = true,
}

Class = require("lib.middleclass")
UI = require("ui")
Json = require("lib.json")
StateManager = require("src.stateManager")
Flux = require("lib.flux")

require("src.GraphicsManager")
require("src.Project")
require("src.Player")
require("src.Renderer")
require("src.TextRender")
require("src.ProjectPluginManager")
require("src.AudioManager")
require("src.KeyframeManager")

Nebulae = {
    pluginsDir = "plugins"
}

Translations = {}
Language = "en"

function LoadTranslations()
    for _, filename in ipairs(love.filesystem.getDirectoryItems("assets/translations")) do
        local path = "assets/translations/" .. filename

        print("Reloading translation file:", filename)

        local ok, content = pcall(love.filesystem.read, path)
        if ok then
            local ok2, translation = pcall(Json.decode, content)
            if ok2 then
                Translations[translation.short] = translation
            else
                print("JSON decode failed for", filename)
            end
        else
            print("Failed to read file:", filename)
        end
    end

    love.window.setTitle(GetTranslation("title") .. " v" .. AppVersion)
end

function GetTranslation(...)
    local args = { ... }
    local translation = Translations[Language]

    -- Go through the path
    for i = 1, #args do
        if translation and type(translation) == "table" then
            translation = translation[args[i]]
        else
            break
        end
    end

    -- If we found a string, return it
    if type(translation) == "string" then
        return translation
    end

    -- Otherwise, fallback to a joined path as a string
    return table.concat(args, ".")
end

function RecursiveSearchDir(dir, flatTable)
    flatTable = flatTable or {} -- Initialize the table if not provided

    local items = love.filesystem.getDirectoryItems(dir)
    for _, item in ipairs(items) do
        local fullPath = dir .. "/" .. item
        local info = love.filesystem.getInfo(fullPath)
        if info then
            if info.type == "directory" then
                -- Add the directory to the flat table
                table.insert(flatTable, { path = fullPath, type = "directory" })
                -- Recursively search the subdirectory
                RecursiveSearchDir(fullPath, flatTable)
            elseif info.type == "file" then
                -- Add the file to the flat table
                table.insert(flatTable, { path = fullPath, type = "file" })
            end
        end
    end

    return flatTable
end

function GetDirectory()
    local path = love.filesystem.getSource()
    if string.find(path, "%.") then
        path = love.filesystem.getSourceBaseDirectory()
    end

    return path
end

function RgbToHex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

function RgbToBGRHex(r, g, b)
    return string.format("#%02X%02X%02X", b, g, r)
end

function HexToRGB(hex)
    local r, g, b = hex:match("#?(%x%x)(%x%x)(%x%x)")
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

function HexToBGR(hex)
    local b, g, r = hex:match("#?(%x%x)(%x%x)(%x%x)")
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

function PreHookFunction(func, hook)
    local oldFunc = func
    func = function(...)
        local ret = hook(...)
        return oldFunc(...), ret
    end
    return func
end

function PostHookFunction(func, hook)
    local oldFunc = func
    func = function(...)
        local ret = oldFunc(...)
        return ret, hook(...)
    end
    return func
end

local curProfiles = {}

function StartProfile(name)
    curProfiles[name] = socket.gettime()
end

function EndProfile(name)
    local start = curProfiles[name]
    if start then
        print(name .. " took " .. (socket.gettime() - start) .. " seconds")
    end
end

-- Euclidean algorithm for GCD
function GCD(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return math.abs(a)
end

-- Simplify a fraction
function SimplifyFraction(numerator, denominator)
    local divisor = GCD(numerator, denominator)
    return math.floor(numerator / divisor), math.floor(denominator / divisor)
end

function GetAspectRatio(width, height)
    local aspectWidth, aspectHeight = SimplifyFraction(width, height)
    return ("%d:%d"):format(aspectWidth, aspectHeight)
end

function ForceDraw(func)
    func()
    love.graphics.present()
end

function ApplyLetterbox(targetWidth, targetHeight, x, y)
    -- Default x and y to 0 if not provided
    x = x or 0
    y = y or 0

    -- Adjust the target width and height based on x and y offsets
    targetWidth = targetWidth - x
    targetHeight = targetHeight - y

    -- Get the window dimensions
    local windowWidth, windowHeight = love.graphics.getDimensions()

    -- Calculate scaling factor based on the window size and target size
    local scale = math.min(windowWidth / targetWidth, windowHeight / targetHeight)

    -- Calculate the offset needed to center the content
    local offsetX = math.floor((windowWidth - targetWidth * scale) / 2) + x
    local offsetY = math.floor((windowHeight - targetHeight * scale) / 2) + y

    -- Apply the translation and scaling transformation
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale)

    -- Return the function that resets the transformations when called
    return function()
        love.graphics.pop()
    end
end

-- Returns offsetX, offsetY, scale
function LetterboxFitScale(x, y, width, height, contentWidth, contentHeight)
    width = width - x
    height = height - y
    local targetRatio = contentWidth / contentHeight
    local containerRatio = width / height

    local scale
    if containerRatio > targetRatio then
        scale = height / contentHeight
    else
        scale = width / contentWidth
    end

    local newWidth = contentWidth * scale
    local newHeight = contentHeight * scale

    local offsetX = x + (width - newWidth) / 2
    local offsetY = y + (height - newHeight) / 2

    return offsetX, offsetY, scale
end

function FormatToTime(seconds)
    local minutes = math.floor(seconds / 60)
    local seconds = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

function SanitizeFilename(input, max_length)
    max_length = max_length or 255

    -- Replace unsafe characters with underscore
    local safe = input:gsub("[^%w%-_%.]", "_")

    -- Remove leading/trailing dots and spaces (problematic on Windows)
    safe = safe:gsub("^%s+", ""):gsub("%s+$", "")
    safe = safe:gsub("^%.*", ""):gsub("%.*$", "")

    -- Truncate to the max length
    if #safe > max_length then
        safe = safe:sub(1, max_length)
    end

    -- Make sure the name isn't empty
    if safe == "" then
        safe = "_"
    end

    return safe
end

function EnsureDirectory(name)
    if not NativeFS.getInfo(name) then
        NativeFS.createDirectory(name)
    end
end

function math.average(numTable, ...)
    if type(numTable) == "number" then
        return math.average({ numTable, ... })
    elseif type(numTable) == "table" then
        local sum = 0
        local count = 0
        for _, v in ipairs(numTable) do
            sum = sum + v
            count = count + 1
        end
        return sum / count
    else
        error("Expected number or table, got " .. type(numTable))
    end
end

-- turns 1280x720 into something like 0.239487x0.243824
function RelativeScale(w1, h1, w2, h2)
    return w2 / w1, h2 / h1
end
