local state = {
    menuUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    menuUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
    menuUITextboxBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIBackgroundColor = { 0.1, 0.1, 0.1 },
    deleteButtonBackgroundColor = { 1, 0.2, 0.2 },
    deleteButtonBackgroundHoveredColor = { 1, 0.3, 0.3 },
    deleteButtonBackgroundPressedColor = { 1, 0.4, 0.4 },
}

local function handleUI(w, h)
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()
    texts = {}

    local cancelButton = UI.addNew("button", {
        x = 50,
        y = 350,
        width = (w / 2) - 60,
        height = 40,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        text = GetTranslation("projectDeletion", "cancelButton"),
        borderRadius = 8,
        font = MedBigFontArial,
        onRelease = function()
            StateManager.switch(state.stateAfter, unpack(state.args))
        end
    })

    local deleteButton = UI.addNew("button", {
        x = (w / 2) + 10,
        y = 350,
        width = (w / 2) - 60,
        height = 40,
        backgroundColor = state.deleteButtonBackgroundColor,
        backgroundColorHover = state.deleteButtonBackgroundHoveredColor,
        backgroundColorPress = state.deleteButtonBackgroundPressedColor,
        text = GetTranslation("projectDeletion", "deleteButton"),
        borderRadius = 8,
        font = MedBigFontArial,
        onRelease = function()
            Project:deleteProject(state.folderName)
            StateManager.switch("menu")
        end
    })

    if love.window.fromPixels(w) < 500 then
        cancelButton.width = w - 100
        deleteButton.width = w - 100
        deleteButton.x = 50
        deleteButton.y = cancelButton.y + cancelButton.height + 10
    end
end

function state:enter(folderName, stateAfter, ...)
    self.folderName = folderName
    self.projectName = Project:fetchProjectMeta(folderName).name
    self.stateAfter = stateAfter
    self.args = { ... }
    handleUI(love.graphics.getDimensions())
end

function state:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(GetTranslation("projectDeletion", "deleteProjectWarning"):format(self.projectName), BigFontArial,
    0, 50, love.graphics.getWidth(), "center")
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
