local creator = {
    project = nil,
    creatorUIMenubarBackgroundColor = { 0.2, 0.2, 0.2 },
    creatorUIMenubarSidebarColor = { 0.2, 0.2, 0.2 },
    creatorUIDropdownBackgroundColor = { 0.2, 0.2, 0.2 },
    creatorUIButtonBackgroundColor = { 0.2, 0.2, 0.2 },
    creatorUIButtonBackgroundHoveredColor = { 0.3, 0.3, 0.3 },
    creatorUIButtonBackgroundPressedColor = { 0.4, 0.4, 0.4 },
    creatorUILabelBackgroundColor = { 0.2, 0.2, 0.2 },
    creatorUIBackgroundColor = { 0.1, 0.1, 0.1 },
    deleteButtonBackgroundColor = { 1, 0.2, 0.2 },
    deleteButtonBackgroundHoveredColor = { 1, 0.3, 0.3 },
    deleteButtonBackgroundPressedColor = { 1, 0.4, 0.4 },
    menubarHeight = 20,
    timelineHeight = 200
}
local timelineComponent = require("src.components.timeline")

local function handleUI(w, h)
    UI.removeAll()
    love.graphics.setBackgroundColor(creator.creatorUIBackgroundColor)
    local menubar = UI.addNew("panel", {
        x = 0,
        y = 0,
        width = w,
        height = creator.menubarHeight,
        backgroundColor = creator.creatorUIMenubarBackgroundColor
    })
    creator.menubar = menubar

    local projectMenubarDropdown = UI.addNew("dropdown", {
        x = 0,
        y = menubar.height,
        width = 100,
        height = 0,
        backgroundColor = creator.creatorUIDropdownBackgroundColor
    })
    projectMenubarDropdown.exclusions = { menubar }
    local projectMenubarDropdownButtons = {
        {
            text = GetTranslation("creator", "projectTab", "renderButton"),
            func = function()
                StateManager.switch("renderSettings", "creator", creator.project.folderName, creator.project.folderName)
            end
        },
        {
            text = GetTranslation("creator", "projectTab", "unloadButton"),
            func = function()
                StateManager.switch("menu")
            end
        },
        {
            text = GetTranslation("creator", "projectTab", "deleteButton"),
            func = function()
                StateManager.switch("projectDeletion", creator.project.folderName, "creator", creator.project.folderName)
            end
        },
    }
    for i, v in ipairs(projectMenubarDropdownButtons) do
        local button = UI.new("button", {
            x = 0,
            y = 20 * (i - 1),
            width = projectMenubarDropdown.width,
            height = 19,
            backgroundColor = creator.creatorUIButtonBackgroundColor,
            backgroundColorHover = creator.creatorUIButtonBackgroundHoveredColor,
            backgroundColorPress = creator.creatorUIButtonBackgroundPressedColor,
            text = v.text,
            onRelease = v.func
        })
        projectMenubarDropdown.height = projectMenubarDropdown.height + 20
        projectMenubarDropdown:add(button)
    end
    projectMenubarDropdown:close()
    creator.projectMenubarDropdown = projectMenubarDropdown

    local projectMenubarButton = UI.addNew("button", {
        x = 0,
        y = 0,
        width = 50,
        height = creator.menubarHeight,
        backgroundColor = creator.creatorUIMenubarSidebarColor,
        text = GetTranslation("creator", "projectTab", "name"),
        onRelease = function()
            projectMenubarDropdown:toggle()
        end
    })
    creator.projectMenubarButton = projectMenubarButton

    local playToggleButton = UI.addNew("button", {
        x = 50,
        y = 0,
        width = 50,
        height = creator.menubarHeight,
        backgroundColor = creator.creatorUIMenubarSidebarColor,
        text = GetTranslation("creator", "playButton"),
        onRelease = function(obj)
            creator.project.player:toggle()
            obj.text = creator.project.player.isPlaying and GetTranslation("creator", "pauseButton") or
                GetTranslation("creator", "playButton")
        end
    })
    creator.playToggleButton = playToggleButton

    local playerTimeLabel = UI.addNew("label", {
        x = 100,
        y = 0,
        width = 100,
        height = creator.menubarHeight,
        backgroundColor = creator.creatorUIMenubarSidebarColor,
        text = "0:00/0:00",
        z = 100
    })
    creator.playerTimeLabel = playerTimeLabel

    playerTimeLabel.text = string.format("%02d:%02d/%02d:%02d",
        math.floor(creator.project.player.time / 60),
        math.floor(creator.project.player.time % 60),
        math.floor(creator.project.player.duration / 60),
        math.floor(creator.project.player.duration % 60))

    menubar:add(projectMenubarButton)
    menubar:add(playToggleButton)
end

function creator:enter(name)
    self.project = Project(name)
    self.project:load(function() end)
    handleUI(love.graphics.getDimensions())
    DiscordRichPresence.details = "Editing '" .. self.project.name .. "'"
end

function creator:resize(w, h)
    handleUI(w, h)
end

function creator:draw()
    local project = self.project
    local graphicsManager = project.graphicsManager

    local ox, oy, scale = LetterboxFitScale(0, creator.menubarHeight, love.graphics.getWidth(), love.graphics.getHeight(),
        graphicsManager.width, graphicsManager.height + 200)
    love.graphics.push()
    love.graphics.translate(ox, oy)
    love.graphics.scale(scale)
    graphicsManager:draw()
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
    UI.draw()
    -- timelineComponent:draw()
end

function creator:update(dt)
    UI.update(dt)
    creator.playerTimeLabel.text = string.format("%02d:%02d/%02d:%02d",
        math.floor(creator.project.player.time / 60),
        math.floor(creator.project.player.time % 60),
        math.floor(creator.project.player.duration / 60),
        math.floor(creator.project.player.duration % 60))
end

function creator:leave()
    self.project:unload()
    self.project = nil
    UI.removeAll()
end

return creator
