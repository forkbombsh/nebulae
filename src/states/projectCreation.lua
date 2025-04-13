local state = {
    menuUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    menuUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
    menuUITextboxBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIBackgroundColor = { 0.1, 0.1, 0.1 },
}
local projectName = "Untitled"
local projectWidth = 1280
local projectHeight = 720
local projectAlreadyExists = false

local function removeNonNumbers(str)
    local numStr = str:gsub("[^0-9]", "")
    return tonumber(numStr) or 0 -- or use projectWidth or 1280 if you prefer
end

local function checkForProjectExistance(name)
    projectAlreadyExists = false
    for i, v in ipairs(Project:getProjectList()) do
        local proj = Project:fetchProjectMeta(v)
        if name:lower() == proj.name:lower() then
            projectAlreadyExists = true
            break
        end
    end
end

local function handleUI(w, h)
    UI.removeAll()
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    checkForProjectExistance(projectName)

    local nameTextbox = UI.addNew("textbox", {
        x = 50,
        y = 100,
        width = w - 100,
        height = 40,
        textLimit = 255,
        hasBackground = true,
        backgroundColor = state.menuUITextboxBackgroundColor,
        borderRadius = 8,
        text = projectName,
        font = MedFontArial,
        multiline = false,
        onTextChange = function(_, text)
            projectName = text
            checkForProjectExistance(projectName)
        end
    })

    local widthThing = UI.addNew("textbox", {
        x = 50,
        y = 200,
        width = w - 100,
        height = 40,
        textLimit = 5,
        hasBackground = true,
        font = MedFontArial,
        backgroundColor = state.menuUITextboxBackgroundColor,
        borderRadius = 8,
        text = tostring(projectWidth),
        multiline = false,
        onTextChange = function(widthThing, text)
            local newVal = removeNonNumbers(text)
            if newVal then
                projectWidth = math.max(newVal, 300)
                widthThing.text = tostring(projectWidth)
            end
        end
    })

    local heightThing = UI.addNew("textbox", {
        x = 50,
        y = 270,
        width = w - 100,
        height = 40,
        textLimit = 5,
        hasBackground = true,
        font = MedFontArial,
        backgroundColor = state.menuUITextboxBackgroundColor,
        borderRadius = 8,
        multiline = false,
        text = tostring(projectHeight),
        onTextChange = function(heightThing, text)
            local newVal = removeNonNumbers(text)
            if newVal then
                projectHeight = math.max(newVal, 300)
                heightThing.text = tostring(projectHeight)
            end
        end
    })

    local cancelButton = UI.addNew("button", {
        x = 50,
        y = 350,
        width = (w / 2) - 60,
        height = 40,
        hasBackground = true,
        font = MedFontArial,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        borderRadius = 8,
        text = GetTranslation("projectCreation", "cancelProjectButton"),
        onRelease = function()
            StateManager.switch("menu")
        end
    })

    local createButton = UI.addNew("button", {
        x = (w / 2) + 10,
        y = 350,
        width = (w / 2) - 60,
        height = 40,
        hasBackground = true,
        font = MedFontArial,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        borderRadius = 8,
        text = GetTranslation("projectCreation", "createProjectButton"),
        onRelease = function()
            local project = Project:getProjectMetaFromDefault(projectName, projectWidth, projectHeight)
            local folderDir = Project:createNewProject(project)
            print(folderDir)
            StateManager.switch("creator", folderDir)
        end
    })

    if love.window.fromPixels(w) < 500 then
        cancelButton.width = w - 100
        createButton.width = w - 100
        createButton.x = 50
        createButton.y = cancelButton.y + cancelButton.height + 10
    end
end

function state:enter()
    handleUI(love.graphics.getDimensions())
end

function state:draw()
    if projectAlreadyExists then
        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.print(GetTranslation("projectCreation", "projectAlreadyExists"), MedFontArial, 50, 140)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(GetTranslation("projectCreation", "projectNameLabel"), MedFontArial, 50, 80)
    love.graphics.print(GetTranslation("projectCreation", "projectWidthLabel"), MedFontArial, 50, 180)
    love.graphics.print(GetTranslation("projectCreation", "projectHeightLabel"), MedFontArial, 50, 250)
    love.graphics.print(("(%s)"):format(GetAspectRatio(projectWidth, projectHeight)), MedFontArial, 50, 320)
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
