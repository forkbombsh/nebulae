local utf8 = require("utf8")

NativeFS = require("lib.nativefs")
assert(NativeFS.getInfo("assets"),
    "\n\nThe assets directory was not found. without it, Nebulae cannot function.\nPlease either reinstall Nebulae or download the assets off the github repo.")

TempPath = os.tmpname()
NativeFS.createDirectory(TempPath)

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    msg = tostring(msg)

    error_printer(msg, 2)

    if not love.window or not love.graphics or not love.event then
        return
    end

    if not love.graphics.isCreated() or not love.window.isOpen() then
        local success, status = pcall(love.window.setMode, 800, 600)
        if not success or not status then
            return
        end
    end

    -- Reset state.
    if love.mouse then
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
        love.mouse.setRelativeMode(false)
        if love.mouse.isCursorSupported() then
            love.mouse.setCursor()
        end
    end
    if love.joystick then
        -- Stop all joystick vibrations.
        for i, v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration()
        end
    end
    if love.audio then love.audio.stop() end

    love.graphics.reset()
    love.graphics.setFont(love.graphics.newFont(14))

    love.graphics.setColor(1, 1, 1)

    local trace = debug.traceback()

    love.graphics.origin()

    local sanitizedmsg = {}
    for char in msg:gmatch(utf8.charpattern) do
        table.insert(sanitizedmsg, char)
    end
    sanitizedmsg = table.concat(sanitizedmsg)

    local err = {}

    table.insert(err, "Error\n")
    table.insert(err, sanitizedmsg)

    if #sanitizedmsg ~= #msg then
        table.insert(err, "Invalid UTF-8 string in error message.")
    end

    table.insert(err, "\n")

    for l in trace:gmatch("(.-)\n") do
        if not l:match("boot.lua") then
            l = l:gsub("stack traceback:", "Traceback\n")
            table.insert(err, l)
        end
    end

    local p = table.concat(err, "\n")

    p = p:gsub("\t", "")
    p = p:gsub("%[string \"(.-)\"%]", "%1")

    local function draw()
        if not love.graphics.isActive() then return end
        local pos = 70
        love.graphics.clear(89 / 255, 157 / 255, 220 / 255)
        love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
        love.graphics.present()
    end

    local fullErrorText = p
    local function copyToClipboard()
        if not love.system then return end
        love.system.setClipboardText(fullErrorText)
        p = p .. "\nCopied to clipboard!"
    end

    if love.system then
        p = p .. "\n\nPress Ctrl+C or tap to copy this error"
    end

    local function getSurroundingLines(traceback, context)
        local file, line = traceback:match('\n%s*([^:\n]+):(%d+):')
        line = tonumber(line)
        if not file or not line then return nil end

        local ok, source = pcall(function()
            local f = io.open(file, "r")
            if not f then return nil end
            local lines = {}
            for l in f:lines() do
                table.insert(lines, l)
            end
            f:close()
            return lines
        end)

        if not ok or not source then return nil end

        local start_line = math.max(1, line - context)
        local end_line = math.min(#source, line + context)

        local snippet = {}
        for i = start_line, end_line do
            local prefix = (i == line) and ">> " or "   "
            table.insert(snippet, string.format("%s%4d | %s", prefix, i, source[i]))
        end

        return table.concat(snippet, "\n")
    end

    local snippet = getSurroundingLines(trace, 3)
    print(snippet)
    if snippet then
        p = p .. "\n\nCode snippet:\n" .. snippet
    end

    Cleanup()

    return function()
        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" then
                return 1
            elseif e == "keypressed" and a == "escape" then
                return 1
            elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
                copyToClipboard()
            elseif e == "touchpressed" then
                local name = love.window.getTitle()
                if #name == 0 or name == "Untitled" then name = "Game" end
                local buttons = { "OK", "Cancel" }
                if love.system then
                    buttons[3] = "Copy to clipboard"
                end
                local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", buttons)
                if pressed == 1 then
                    return 1
                elseif pressed == 3 then
                    copyToClipboard()
                end
            end
        end

        draw()

        if love.timer then
            love.timer.sleep(0.1)
        end
    end
end

if love.filesystem.isFused() then
    local dir = love.filesystem.getSourceBaseDirectory()
    love.filesystem.mount(dir, "")
end

love.filesystem.setIdentity("nebulae")
love.filesystem.createDirectory("cached")

function Cleanup()
    if love.filesystem.isFused() then
        local dir = love.filesystem.getSourceBaseDirectory()
        love.filesystem.unmount(dir)
    end
    RemoveDirectory(TempPath)
    DiscordRPC.shutdown()
end
