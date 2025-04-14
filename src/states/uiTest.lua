local state = {}

local function setupUI()
    UI.removeAll()

    local panel = UI.addNew("panel", {
        x = 10,
        y = 10,
        width = 400,
        height = 400,
        backgroundColor = { 0, 0, 0 },
        borderColor = { 1, 1, 1 },
        borderRadius = 10,
        z = 1
    })

    for x = 1, 3 do
        for y = 1, 10 do
            local button = UI.new("button", {
                x = x * 110-80,
                y = y * 60-30,
                width = 100,
                height = 50,
                backgroundColor = { 0, 0, 0 },
                borderColor = { 1, 1, 1 },
                borderRadius = 10,
                z = 2
            })
            panel:add(button)
        end
    end
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
