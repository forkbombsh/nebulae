local socket = require("socket")
print("Loading...")
_G.StartLoadTimeStartTime = socket.gettime()
local project = require("config.project")
require("setup")

local oldreq = require
local cached = {}
local stack = {}

function require(path)
    local oldTime = socket.gettime()
    table.insert(stack, path)
    
    local function indent()
        return string.rep("|", #stack)
    end
    
    print("!" .. " loading " .. path)

    local function finish()
        local newTime = socket.gettime()
        print(indent() .. " required " .. path .. " in " .. (newTime - oldTime) .. " seconds")
        table.remove(stack)
    end

    if cached[path] then
        finish()
        return cached[path]
    else
        local result = oldreq(path)
        cached[path] = result
        finish()
        return result
    end
end

function love.conf(t)
    -- Set window properties
    t.window.width = 1280
    t.window.height = 720
    t.window.fullscreen = false
    t.window.resizable = true
    t.window.vsync = true
    t.window.title = project.name .. " v" .. project.version
    t.audio.mixwithsystem = false
    t.window.msaa = 4
    t.console = true
    t.window.icon = "assets/logo/nebulae-letter-circle.png"
    t.identity = "nebulae"

    -- Check if renderers are defined in the project and apply them
    if type(t.graphics) == "table" then
        t.graphics.renderers = project.renderers
    elseif type(t) == "table" then
        t.renderers = project.renderers
    end
end