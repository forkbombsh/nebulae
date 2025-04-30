local state = {}

local text = TextRender("Hello World!", 100, 100, 20, 10, 0, nil, nil)

function state:draw()
    text:draw()
end

return state
