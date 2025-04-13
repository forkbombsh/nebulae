jit.off()
require("global")

if not NativeFS.getInfo("projects") then
    NativeFS.createDirectory("projects")
end

if IsMobile then
    love.window.setMode(1, 2, { fullscreen = false })
end

for i, v in ipairs(love.filesystem.getDirectoryItems("src/states")) do
    if string.sub(v, -4) == ".lua" then
        StateManager.registerState(string.sub(v, 1, -5), require("src.states." .. string.sub(v, 1, -5)))
    end
end

LoadTranslations()

love.keyboard.setKeyRepeat(true)

StateManager.switch("menu")

if arg[2] == "debug" then
    require("lldebugger").start()
end

-- a bunch of callbacks, boring

function love.draw()
    StateManager.passEvent("draw")
    love.graphics.printf(tostring(love.timer.getFPS()) .. " FPS", 0, 0, love.graphics.getWidth(), "right")
end

function love.update(dt)
    dt = Renderer:update(dt)
    StateManager.passEvent("update", dt)
    -- TextRender:updateAll(dt)
    Project:updateAll(dt)
end

function love.mousepressed(x, y, b)
    UI.sendEventSelf("mousepressed", x, y, b)
    StateManager.passEvent("mousepressed", x, y, b)
end

function love.mousereleased(x, y, b)
    UI.sendEventSelf("mousereleased", x, y, b)
    StateManager.passEvent("mousereleased", x, y, b)
end

function love.wheelmoved(x, y)
    UI.sendEventSelf("wheelmoved", x, y)
    StateManager.passEvent("wheelmoved", x, y)
end

function love.mousemoved(x, y, dx, dy)
    UI.sendEventSelf("mousemoved", x, y, dx, dy)
    StateManager.passEvent("mousemoved", x, y, dx, dy)
end

function love.keypressed(key)
    UI.sendEventSelf("keypressed", key)
    StateManager.passEvent("keypressed", key)
    if love.keyboard.isDown("lctrl", "rctrl") and love.keyboard.isDown("lshift", "rshift") then
        if key == "l" then
            LoadTranslations()
        end
    end
end

function love.keyreleased(key)
    UI.sendEventSelf("keyreleased", key)
    StateManager.passEvent("keyreleased", key)
end

function love.textinput(char)
    UI.sendEventSelf("textinput", char)
    StateManager.passEvent("textinput", char)
end

function love.resize(w, h)
    UI.sendEventSelf("resize", w, h)
    StateManager.passEvent("resize", w, h)
    -- rs.resize(w, h)
end

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end

            love.graphics.present()
        end

        -- no sleep
    end
end

local utf8 = require("utf8")

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    end

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

    love.graphics.setColor(1, 1, 1)

    local trace = debug.traceback()

    love.graphics.origin()

    local sanitizedmsg = {}
    for char in msg:gmatch(utf8.charpattern) do
        table.insert(sanitizedmsg, char)
    end
    sanitizedmsg = table.concat(sanitizedmsg)

    local err = {}

    table.insert(err, "Runtime Error\n")
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

    local function showMessageBox()
        local buttonnum = love.window.showMessageBox("LÖVE", p, { "Report Error", "Close" }, "error", true)
    end
    showMessageBox()
end

-- function love.errorhandler(msg)
--     msg = tostring(msg)

--     error_printer(msg, 2)

--     if not love.window or not love.graphics or not love.event then
--         return
--     end

--     if not love.graphics.isCreated() or not love.window.isOpen() then
--         local success, status = pcall(love.window.setMode, 800, 600)
--         if not success or not status then
--             return
--         end
--     end

--     -- Reset state.
--     if love.mouse then
--         love.mouse.setVisible(true)
--         love.mouse.setGrabbed(false)
--         love.mouse.setRelativeMode(false)
--         if love.mouse.isCursorSupported() then
--             love.mouse.setCursor()
--         end
--     end
--     if love.joystick then
--         -- Stop all joystick vibrations.
--         for i, v in ipairs(love.joystick.getJoysticks()) do
--             v:setVibration()
--         end
--     end
--     if love.audio then love.audio.stop() end

--     love.graphics.reset()
--     local font = love.graphics.newFont(14)

--     love.graphics.setColor(1, 1, 1)

--     local trace = debug.traceback()

--     love.graphics.origin()

--     local sanitizedmsg = {}
--     for char in msg:gmatch(utf8.charpattern) do
--         table.insert(sanitizedmsg, char)
--     end
--     sanitizedmsg = table.concat(sanitizedmsg)

--     local err = {}

--     table.insert(err, "Error\n")
--     table.insert(err, sanitizedmsg)

--     if #sanitizedmsg ~= #msg then
--         table.insert(err, "Invalid UTF-8 string in error message.")
--     end

--     table.insert(err, "\n")

--     for l in trace:gmatch("(.-)\n") do
--         if not l:match("boot.lua") then
--             l = l:gsub("stack traceback:", "Traceback\n")
--             table.insert(err, l)
--         end
--     end

--     local p = table.concat(err, "\n")

--     p = p:gsub("\t", "")
--     p = p:gsub("%[string \"(.-)\"%]", "%1")

--     local function draw()
--         if not love.graphics.isActive() then return end
--         local pos = 70
--         love.graphics.clear(0.1, 0.1, 0.1)
--         UI.draw()
--         love.graphics.present()
--     end

--     local fullErrorText = p
--     local function copyToClipboard()
--         if not love.system then return end
--         love.system.setClipboardText(fullErrorText)
--         p = p .. "\nCopied to clipboard!"
--     end

--     if love.system then
--         p = p .. "\n\nPress Ctrl+C or tap to copy this error"
--     end

--     for i, v in pairs(Project.projects) do
--         v:unload()
--     end

--     local function handleUI(w, h)
--         UI.removeAll()
--         UI.addNew("label", {
--             x = 10,
--             y = 10,
--             width = w - 20,
--             height = h - 20,
--             backgroundColor = { 0.2, 0.2, 0.2 },
--             text = p,
--             font = font,
--             wrapText = true,
--             hasBackground = false,
--             z = 2
--         })
--         UI.addNew("button", {
--             x = 20,
--             y = h - 10 - 10 - 40 - 40 - 10 - 40 - 10,
--             width = w - 40,
--             height = 40,
--             backgroundColor = { 0.2, 0.2, 0.2 },
--             text = "Report Error",
--             font = font,
--             onClick = copyToClipboard,
--             z = 3,
--             borderRadius = 8
--         })
--         UI.addNew("button", {
--             x = 20,
--             y = h - 10 - 10 - 40 - 40 - 10,
--             width = w - 40,
--             height = 40,
--             backgroundColor = { 0.2, 0.2, 0.2 },
--             text = "Copy Error",
--             font = font,
--             onClick = copyToClipboard,
--             z = 3,
--             borderRadius = 8
--         })
--         UI.addNew("button", {
--             x = 20,
--             y = h - 10 - 10 - 40,
--             width = w - 40,
--             height = 40,
--             backgroundColor = { 0.2, 0.2, 0.2 },
--             text = "Close",
--             font = font,
--             onClick = love.event.quit,
--             z = 3,
--             borderRadius = 8
--         })
--     end

--     return function()
--         love.event.pump()

--         for e, a, b, c, d in love.event.poll() do
--             if e == "quit" then
--                 return 1
--             elseif e == "keypressed" and a == "escape" then
--                 return 1
--             elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
--                 copyToClipboard()
--             end
--             UI.sendEventSelf(e, a, b, c, d)
--         end

--         handleUI(love.graphics.getDimensions())
--         draw()
--         local dt = love.timer.getDelta()
--         UI.update(dt)

--         if love.timer then
--             love.timer.sleep(0.01)
--         end
--     end
-- end
