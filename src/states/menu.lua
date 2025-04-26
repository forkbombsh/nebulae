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

local panelAmt = 2

local function getPosAndSizeOfPanel(index)
    local w = love.graphics.getWidth()
    local panelWidth = w / panelAmt
    local panelX = (index - 1) * panelWidth
    local panelY = 0
    return panelX + 50, panelY, panelWidth - 100
end

-- 🧩 NEW: Grid positioning helper
local function getGridPos(index, columns, panelWidth, panelHeight, spacing, startX, startY)
    local col = (index - 1) % columns
    local row = math.floor((index - 1) / columns)
    local x = startX + col * (panelWidth + spacing)
    local y = startY + row * (panelHeight + spacing)
    return x, y
end

local function handleUI(w, h)
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()

    state.createProjectButton = nil
    state.loadProjectLabel    = nil

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

    local projectList         = Project:getProjectList()

    if #projectList > 0 then
        local text = GetTranslation("menu", "projectsLabel")
        local x, y, w = getPosAndSizeOfPanel(1)
        local loadProjectLabel = UI.addNew("label", {
            x = x,
            y = 220 + y,
            width = w,
            height = 50,
            font = MedBigFontArial,
            backgroundColor = state.menuUILabel2BackgroundColor,
            text = text,
            borderRadius = 8,
            z = -1
        })
        state.loadProjectLabel = loadProjectLabel

        local projectsPanel = UI.addNew("panel", {
            x = x,
            y = 260 + y,
            width = w,
            height = 380,
            borderRadius = 8,
            backgroundColor = state.menuUILabel2BackgroundColor
        })

        for i, v in ipairs(projectList) do
            local proj = Project:fetchProjectMeta(v)
            local y = i * 50 - 40
            local loadButton = UI.new("button", {
                x = 10,
                y = y,
                width = 330,
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
            local deleteButton = UI.new("button", {
                x = 10 + 340,
                y = y,
                width = 40,
                font = MedFontArial,
                height = 40,
                backgroundColor = state.deleteButtonBackgroundColor,
                backgroundColorHover = state.deleteButtonBackgroundHoveredColor,
                backgroundColorPress = state.deleteButtonBackgroundPressedColor,
                text = "Del",
                borderRadius = 8,
                onRelease = function()
                    StateManager.switch("projectDeletion", v, "menu")
                end,
                z = 2 + i
            })
            projectsPanel:add(loadButton)
            projectsPanel:add(deleteButton)
        end
    end

    -- 🧱 DEMO GRID PANELS
    local gridStartX = 50
    local gridStartY = 700
    local gridColumns = 3
    local gridPanelWidth = 200
    local gridPanelHeight = 100
    local gridSpacing = 20
    local panelCount = 6

    for i = 1, panelCount do
        local x, y = getGridPos(i, gridColumns, gridPanelWidth, gridPanelHeight, gridSpacing, gridStartX, gridStartY)

        UI.addNew("panel", {
            x = x,
            y = y,
            width = gridPanelWidth,
            height = gridPanelHeight,
            borderRadius = 8,
            backgroundColor = state.menuUILabel2BackgroundColor
        })
    end
end

function state:enter()
    handleUI(love.graphics.getDimensions())
    DiscordRichPresence.details = "Menu"
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
        love.window.focus()
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
