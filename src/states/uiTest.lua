local state = {}

local function setupUI()
    UI.removeAll()

    local sidebarRight = UI.addNew("panel", {
        x = love.graphics.getWidth() - 100,
        y = 20,
        width = 100,
        height = love.graphics.getHeight() - 200,
        backgroundColor = { 0.2, 0.2, 0.2 }
    })

    local sidebarLeft = UI.addNew("panel", {
        x = 0,
        y = 20,
        width = 100,
        height = love.graphics.getHeight() - 200,
        backgroundColor = { 0.2, 0.2, 0.2 }
    })

    local menubar = UI.addNew("panel", {
        width = love.graphics.getWidth(),
        height = 20,
        x = 0,
        y = 0,
        backgroundColor = { 0.2, 0.2, 0.2 }
    })

    local timelineBar = UI.addNew("panel", {
        width = love.graphics.getWidth(),
        height = 200,
        x = 0,
        y = love.graphics.getHeight() - 200,
        backgroundColor = { 0.2, 0.2, 0.2 }
    })

    local fileDropdown = UI.addNew("dropdown", {
        x = 10,
        y = 30,
        width = 100,
        backgroundColor = { 0.2, 0.2, 0.2 },
        borderColor = { 1, 1, 1 },
        height = 100,
        z = -100
    })

    local openButton = UI.addNew("button", {
        x = 1,
        y = 1,
        width = fileDropdown.width - 2,
        height = menubar.height - 2,
        backgroundColor = { 0.2, 0.2, 0.2 },
        backgroundColorHover = { 0.3, 0.3, 0.3 },
        backgroundColorPress = { 0.4, 0.4, 0.4 },
        text = "Open"
    })

    local saveButton = UI.addNew("button", {
        x = 1,
        y = openButton.by + openButton.height + 1,
        width = fileDropdown.width - 2,
        height = menubar.height - 2,
        backgroundColor = { 0.2, 0.2, 0.2 },
        backgroundColorHover = { 0.3, 0.3, 0.3 },
        backgroundColorPress = { 0.4, 0.4, 0.4 },
        text = "Save"
    })

    local saveAsButton = UI.addNew("button", {
        x = 1,
        y = saveButton.by + saveButton.height + 1,
        width = fileDropdown.width - 2,
        height = menubar.height - 2,
        backgroundColor = { 0.2, 0.2, 0.2 },
        backgroundColorHover = { 0.3, 0.3, 0.3 },
        backgroundColorPress = { 0.4, 0.4, 0.4 },
        text = "Save As..."
    })

    fileDropdown:add(openButton)
    fileDropdown:add(saveButton)
    fileDropdown:add(saveAsButton)

    fileDropdown:close()

    fileDropdown.exclusions = { menubar }

    local fileButton = UI.addNew("button", {
        x = 1,
        y = 0,
        width = 50,
        height = menubar.height - 2,
        backgroundColor = { 0.2, 0.2, 0.2 },
        backgroundColorHover = { 0.3, 0.3, 0.3 },
        backgroundColorPress = { 0.4, 0.4, 0.4 },
        onRelease = function()
            fileDropdown:toggle()
        end,
        text = "File"
    })

    menubar:add(fileButton)
end

function state:enter()
    setupUI()
end

function state:draw()
    UI.draw()
end

function state:update(dt)
    UI.update(dt)
end

function state:resize(w, h)
    setupUI()
end

return state
