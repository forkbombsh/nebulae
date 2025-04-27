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

local col = 0
local z = 0
local function panelTest(x, y, w, h)
    col = col + 0.1
    z = z + 1
    UI.addNew("panel", {
        x = x,
        y = y,
        width = w,
        height = h,
        backgroundColor = { col, col, col },
        z = z,
        borderRadius = 8
    })
end

local buttons = {
    {
        text = "Your Projects",
    },
    {
        text = "Projects other people made",
    }
}

local function handleUI(w, h)
    col = 0
    z = 0
    love.graphics.setBackgroundColor(state.menuUIBackgroundColor)
    UI.removeAll()
    local kirigami = Kirigami
    local screen = kirigami.Region(0, 0, love.graphics.getDimensions())
    local region = screen:padPixels(12)
    panelTest(region:get())
    local padtop, padbot = region:splitVertical(0.2, 0.8)
    panelTest(padbot:get())
    local cols, rows = 1,2

    local grids = padtop:padPixels(8):grid(rows, cols)
    for _, r in ipairs(grids) do
        -- panelTest(r:padPixels(3):get())
        local x, y, w, h = r:padPixels(3):get()
        local text = (buttons[_] and buttons[_] or {text="?"}).text
        UI.addNew("button", {
            x = x,
            y = y,
            width = w,
            height = h,
            text = text,
            backgroundColor = { col, col, col },
            z = z,
            borderRadius = 8,
            font = BigFontArial
        })
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
