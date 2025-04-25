local state = {}
local dotAmount = 0

local function handleUI()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    UI.removeAll()
    UI.addNew("button", {
        x = 50,
        y = 50,
        width = 100,
        height = 50,
        backgroundColor = { 0.2, 0.2, 0.2 },
        backgroundColorHover = { 0.3, 0.3, 0.3 },
        backgroundColorPress = { 0.4, 0.4, 0.4 },
        text = GetTranslation("renderInfo", "renderInfoBackButton"),
        borderRadius = 8,
        font = MedBigFontArial,
        onRelease = function()
            Renderer:finish(false)
        end
    })
end

function state:enter(name, gotostate, renderType, renderArgs, ...)
    handleUI()
    self.project = Project(name)
    self.project:load(function()
        self.project.player:play()
    end)
    local args = { ... }
    Renderer:start(self.project.graphicsManager.width, self.project.graphicsManager.height,
        self.project.graphicsManager.fps, self.project, renderType, renderArgs, function()
            StateManager.switch(gotostate, unpack(args))
        end)
end

function state:draw()
    local reset = ApplyLetterbox(self.project.graphicsManager.width, self.project.graphicsManager.height)
    self.project.graphicsManager:draw()
    reset()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    local dots = ""
    for i = 1, dotAmount do
        dots = dots .. GetTranslation("renderInfo", "renderInfoDot")
    end
    love.graphics.printf(
        ("%s%s\n%s/%s\n%s%%"):format(GetTranslation("renderInfo", "renderInfoLabel"), dots,
            FormatToTime(tonumber(string.format("%.1f", self.project.player.time))),
            FormatToTime(tonumber(string.format("%.1f", self.project.player.duration))),
            string.format("%.2f", (self.project.player.time / self.project.player.duration * 100))), HugeFontArialBold, 0,
        0, love.graphics.getWidth(), "center")
    UI.draw()
end

function state:update(dt)
    dotAmount = math.floor((love.timer.getTime() * 2) % 4)
end

function state:leave()
    self.project:unload()
end

function state:keyreleased(key)
    if key == "escape" then
        Renderer:finish()
    end
end

return state
