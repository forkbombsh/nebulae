local state = {}

local function setupUI()
    UI.removeAll()

    local panel = UI.addNew("panel", {
        x = 10,
        y = 100,
        width = 800,
        height = 800,
        backgroundColor = { 0, 0, 0 },
        borderColor = { 1, 1, 1 },
        borderRadius = 10,
        z = 1
    })

    for x = 1, 10 do
        for y = 1, 10 do
            local button = UI.new("button", {
                x = x * 60-50,
                y = y * 60-50,
                width = 50,
                height = 50,
                backgroundColor = { 0, 0, 0 },
                borderColor = { 1, 1, 1 },
                borderRadius = 10,
                z = 2,
                text = x .. ", " .. y,
                onRelease = function()
                    print(x, y)
                end
            })
            panel:add(button)
        end
    end
    UI.addNew("button", {
        x = 20,
        y = 20,
        width = 100,
        height = 50,
        backgroundColor = { 0, 0, 0 },
        borderColor = { 1, 1, 1 },
        borderRadius = 10,
        z = 2,
        onRelease = function()
            print("hello world")
        end
    })
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
