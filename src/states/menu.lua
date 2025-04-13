local socket = require("socket")
local state = {
    menuUIMenubarBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIMenubarSidebarColor = { 0.2, 0.2, 0.2 },
    menuUIDropdownBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    menuUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
    menuUILabelBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIBackgroundColor = { 0.1, 0.1, 0.1 },
    deleteButtonBackgroundColor = { 1, 0.2, 0.2 },
    deleteButtonBackgroundHoveredColor = { 1, 0.3, 0.3 },
    deleteButtonBackgroundPressedColor = { 1, 0.4, 0.4 },
}

local function copyFolderNativeFS(src, dest)
    -- Create destination directory if it doesn't exist
    if not love.filesystem.getInfo(dest) then
        NativeFS.createDirectory(dest)
    end

    -- Get all items in the source directory
    local items = love.filesystem.getDirectoryItems(src)

    for _, item in ipairs(items) do
        local srcPath = src .. "/" .. item
        local destPath = dest .. "/" .. item
        local itemInfo = love.filesystem.getInfo(srcPath)

        -- If it's a directory, recurse into it
        if itemInfo.type == "directory" then
            copyFolderNativeFS(srcPath, destPath)
        else
            -- If it's a file, copy it
            local data = love.filesystem.read(srcPath)
            NativeFS.write(destPath, data)
        end
    end
end


local function handleUI(w, h)
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()

    state.createProjectButton = nil
    state.loadProjectLabel = nil

    local createProjectButton = UI.addNew("button", {
        x = 50,
        y = 50,
        width = w - 100,
        height = 50,
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

    local importProjectButton = UI.addNew("button", {
        x = 50,
        y = 120,
        width = w - 100,
        height = 50,
        backgroundColor = state.menuUIButtonBackgroundColor,
        backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
        backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
        text = GetTranslation("menu", "importProjectButton"),
        borderRadius = 8,
        font = MedBigFontArial,
        onRelease = function()
            love.window.showFileDialog("openfile", function(fileTable)
                local filepath = fileTable[1]
                if filepath then
                    local success = love.filesystem.mountFullPath(filepath, "tempProjectPath", "read", false)
                    if success then
                        local filename = filepath:match("([^/\\]+)%.%w+$")
                        if love.filesystem.exists("tempProjectPath/metadata.json") and love.filesystem.exists("tempProjectPath/layers.json") then
                            copyFolderNativeFS("tempProjectPath", "projects/" .. filename)
                        end
                        love.filesystem.unmountFullPath(filepath)
                        handleUI(love.graphics.getDimensions())
                    end
                end
            end, {
                title = GetTranslation("importNebFileDialog", "title"),
                attachtowindow = true,
                acceptlabel = GetTranslation("importNebFileDialog", "acceptlabel"),
                cancellabel = GetTranslation("importNebFileDialog", "cancellabel"),
                filters = { [GetTranslation("importNebFileDialog", "projectFileName")] = "neb" }
            })
        end
    })
    state.importProjectButton = importProjectButton

    local projectList = Project:getProjectList()

    if #projectList > 0 then
        local text = GetTranslation("menu", "projectsLabel")
        local loadProjectLabel = UI.addNew("label", {
            x = 50,
            y = 200,
            width = MedBigFontArial:getWidth(text),
            height = 50,
            font = MedBigFontArial,
            backgroundColor = { 0, 0, 0, 0 },
            text = text,
            borderRadius = 8
        })
        state.loadProjectLabel = loadProjectLabel
        for i, v in ipairs(projectList) do
            local proj = Project:fetchProjectMeta(v)
            UI.addNew("button", {
                x = 50,
                y = 200 + i * 40,
                width = w - 250,
                font = MedFontArial,
                height = 40,
                backgroundColor = state.menuUIButtonBackgroundColor,
                backgroundColorHover = state.menuUIButtonBackgroundHoveredColor,
                backgroundColorPress = state.menuUIButtonBackgroundPressedColor,
                text = proj.name or v,
                borderRadius = 8,
                onRelease = function()
                    StateManager.switch("creator", v)
                end,
                z = 2 + i
            })
            UI.addNew("button", {
                x = 50 + w - 225,
                y = 200 + i * 40,
                width = 125,
                font = MedFontArial,
                height = 40,
                backgroundColor = state.deleteButtonBackgroundColor,
                backgroundColorHover = state.deleteButtonBackgroundHoveredColor,
                backgroundColorPress = state.deleteButtonBackgroundPressedColor,
                text = GetTranslation("menu", "deleteProjectButton"),
                borderRadius = 8,
                onRelease = function()
                    StateManager.switch("projectDeletion", v)
                end,
                z = 2 + i
            })
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
end

function state:update(dt)
    UI.update(dt)
end

function state:resize(w, h)
    handleUI(w, h)
    if StartLoadTimeStartTime then
        print("Load Time: " .. (socket.gettime() - StartLoadTimeStartTime))
        StartLoadTimeStartTime = nil
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
