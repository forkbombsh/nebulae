local socket = require("socket")
local state = {
    menuUIMenubarBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIMenubarSidebarColor = { 0.2, 0.2, 0.2 },
    menuUIDropdownBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    menuUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
    menuUILabelBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIBackgroundColor = { 0.1, 0.1, 0.1 }
}

local texts = {}

local function handleUI(w, h)
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()
    texts = {}

    state.createProjectButton = nil
    state.loadProjectLabel = nil
    if state.projectLoadButtons then
        for i, v in ipairs(state.projectLoadButtons) do
            UI.remove(v)
        end
    end
    state.projectLoadButtons = nil

    local createProjectButton = UI.addNew("button", {
        x = 50,
        y = 50,
        width = w - 100,
        height = 100,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        text = GetTranslation("menu", "createProjectButton"),
        borderRadius = 8,
        font = MedBigFontArial,
        onRelease = function()
            StateManager.switch("projectCreation")
        end
    })
    state.createProjectButton = createProjectButton

    local projectList = Project:getProjectList()

    if #projectList > 0 then
        local loadProjectLabel = UI.addNew("label", {
            x = 50,
            y = 200,
            width = w - 100,
            height = 50,
            font = MedBigFontArial,
            backgroundColor = state.menuUILabelBackgroundColor,
            text = GetTranslation("menu", "loadProjectLabel"),
            borderRadius = 8
        })
        state.loadProjectLabel = loadProjectLabel
        state.projectLoadButtons = {}
        for i, v in ipairs(projectList) do
            local proj = Project:fetchProjectMeta(v)
            local button = UI.addNew("button", {
                x = 50,
                y = 200 + i * 40,
                width = w - 100,
                font = MedFontArial,
                height = 40,
                backgroundColor = state.menuUIButtonBackgroundColor,
                backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
                backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
                text = proj.name or v,
                borderRadius = 0,
                onRelease = function()
                    StateManager.switch("creator", v)
                end,
                z = 2 + i
            })
            table.insert(state.projectLoadButtons, button)
        end
    end
end

function state:enter()
    handleUI(love.graphics.getDimensions())
end

function state:draw()
    if self.currentProject and self.currentProject.graphicsManager then
        self.currentProject.graphicsManager:draw()
    end
    UI.draw()
    for i, v in ipairs(texts) do
        v:draw()
    end
end

function state:update(dt)
    UI.update(dt)
end

function state:resize(w, h)
    handleUI(w, h)
    if StartLoadTimeStartTime then
        print("Load Time: " .. (socket.gettime() - StartLoadTimeStartTime))
        StartLoadTimeStartTime=nil
    end
end

function state:leave()
    UI.removeAll()
end

function state:keyreleased(key)
    if key == "f5" then
        handleUI(love.graphics.getDimensions())
    end
end

return state
