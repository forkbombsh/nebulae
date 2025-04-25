local state = {
    menuUIBackgroundColor = { 0.1, 0.1, 0.1 },
    menuUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    menuUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
}

local curEncoderPick = "libx264"

local function handleUI(w, h)
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()

    local cancelButton = UI.addNew("button", {
        x = 50,
        y = h - 80,
        width = (w / 2) - 60,
        height = 40,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        text = GetTranslation("renderSettings", "cancelButton"),
        borderRadius = 8,
        font = MedFontArial,
        onRelease = function()
            StateManager.switch(state.stateAfter, unpack(state.args))
        end
    })

    local renderButton = UI.addNew("button", {
        x = (w / 2) + 10,
        y = h - 80,
        width = (w / 2) - 60,
        height = 40,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        text = GetTranslation("renderSettings", "renderButton"),
        borderRadius = 8,
        font = MedFontArial,
        onRelease = function()
            StateManager.switch("renderInfo", state.folderName, state.stateAfter, Renderer.renderThings[curEncoderPick], {}, unpack(state.args))
        end
    })

    local encoderTextbox = UI.addNew("textbox", {
        x = 50,
        y = 180,
        width = w - 100,
        height = 40,
        backgroundColor = { 0.2, 0.2, 0.2 },
        borderRadius = 8,
        font = MedFontArial,
        text = curEncoderPick,
        onTextChange = function(_, text)
            curEncoderPick = text
        end
    })
end

function state:enter(stateAfter, folderName, ...)
    self.stateAfter = stateAfter
    self.folderName = folderName
    self.args = { ... }
    handleUI(love.graphics.getDimensions())
end

function state:draw()
    UI.draw()
    love.graphics.print(GetTranslation("renderSettings", "title"), BigFontArial, 50, 50)
    love.graphics.print(GetTranslation("renderSettings", "encoderLabel"), MedBigFontArial, 50, 150)
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
