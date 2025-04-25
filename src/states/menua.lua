local socket = require("socket")

local state = {
    menuUIMenubarBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIMenubarSidebarColor = { 0.2, 0.2, 0.2 },
    menuUIDropdownBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    menuUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
    menuUILabelBackgroundColor = { 0.2, 0.2, 0.2 },
    menuUILabel2BackgroundColor = { 0.15, 0.15, 0.15 },
    menuUIBackgroundColor = { 0.1, 0.1, 0.1 },
    deleteButtonBackgroundColor = { 1, 0.2, 0.2 },
    deleteButtonBackgroundHoveredColor = { 1, 0.3, 0.3 },
    deleteButtonBackgroundPressedColor = { 1, 0.4, 0.4 },
}

local function copyFolderNativeFS(src, dest)
    if not love.filesystem.getInfo(dest) then
        NativeFS.createDirectory(dest)
    end
    local items = love.filesystem.getDirectoryItems(src)
    for _, item in ipairs(items) do
        local srcPath = src .. "/" .. item
        local destPath = dest .. "/" .. item
        local itemInfo = love.filesystem.getInfo(srcPath)
        if itemInfo.type == "directory" then
            copyFolderNativeFS(srcPath, destPath)
        else
            local data = love.filesystem.read(srcPath)
            NativeFS.write(destPath, data)
        end
    end
end

local function handleUI(w, h)
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()

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
        end,
        disabled = Lmajor < 12
    })
    state.importProjectButton = importProjectButton

    local panelsGroup = UI.new("group")
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
