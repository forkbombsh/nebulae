require("global")

print("LOVE " .. love._version)
print(jit.version)
print(AppName .. " v" .. AppVersion)
print(jit.os)

EnsureDirectory("projects")
EnsureDirectory("renders")
EnsureDirectory("plugins")

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

function DiscordRPC.ready(userId, username, discriminator, avatar)
    print(string.format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
end

function DiscordRPC.disconnected(errorCode, message)
    print(string.format("Discord: disconnected (%d: %s)", errorCode, message))
end

function DiscordRPC.errored(errorCode, message)
    print(string.format("Discord: error (%d: %s)", errorCode, message))
end

function DiscordRPC.joinGame(joinSecret)
    print(string.format("Discord: join (%s)", joinSecret))
end

function DiscordRPC.spectateGame(spectateSecret)
    print(string.format("Discord: spectate (%s)", spectateSecret))
end

function DiscordRPC.joinRequest(userId, username, discriminator, avatar)
    print(string.format("Discord: join request (%s, %s, %s, %s)", userId, username, discriminator, avatar))
    DiscordRPC.respond(userId, "yes")
end

DiscordRPC.initialize("1365372990191304724", true)

DiscordRichPresence = {
    details = "Loading..."
}

nextPresenceUpdate = 0

StateManager.switch("splash")

if arg[2] == "debug" then
    require("lldebugger").start()
end

-- a bunch of callbacks, boring

function love.draw()
    StateManager.passEvent("draw")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(love.timer.getFPS()) .. " FPS", 0, 0, love.graphics.getWidth(), "right")
end

function love.update(dt)
    dt = Renderer:update(dt)
    StateManager.passEvent("update", dt)
    Project:updateAll(dt)
    Flux.update(dt)
    NLay.update(love.window.getSafeArea())
    if nextPresenceUpdate < love.timer.getTime() then
        DiscordRPC.updatePresence(DiscordRichPresence)
        nextPresenceUpdate = love.timer.getTime() + 2.0
    end
    DiscordRPC.runCallbacks()
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
            StateManager.passEvent("resize", love.graphics.getDimensions())
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
end

function love.quit()
    Cleanup()
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
