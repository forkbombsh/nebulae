local state = {
    menuUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    menuUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
    menuUITextboxBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIBackgroundColor = { 0.1, 0.1, 0.1 },
}

local function handleUI(w, h)
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()
    texts = {}

    local deleteButton = UI.addNew("button", {
        x = 50,
        y = 50,
        width = w - 100,
        height = 50,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        text = GetTranslation("projectDeletion", "deleteButton"),
        borderRadius = 8,
        font = MedBigFontArial,
        onRelease = function()
            Project:deleteProject(state.projectName)
            StateManager.switch("creator")
        end
    })

    if love.window.fromPixels(w) < 500 then
        deleteButton.width = w - 100
        deleteButton.x = 50
    end
end

function state:enter(projectName)
    self.projectName = projectName
    handleUI(love.graphics.getDimensions())
end

function state:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(GetTranslation("projectDeletion", "deleteProjectLabel"), MedFontArial, 50, 80)
    love.graphics.print(("(%s)"):format(self.projectName), MedFontArial, 50, 100)
    UI.draw()
end

function state:update(dt)
    UI.update(dt)
end

function state:resize(w, h)
    handleUI(w, h)
end

function state:leave()
    UI.removeAll()
end

return state