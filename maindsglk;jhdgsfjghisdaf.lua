local NLay = require("lib.nlay")

function love.load()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local root = NLay.constraint(0, 0, screenWidth, screenHeight)

    -- Use a margin table instead of a number
    local padded = NLay.constraint(root, {left=20, right=20, top=20, bottom=20})

    local topHalf, bottomHalf = NLay.splitY(padded, 0.5)
    local leftTop, rightTop = NLay.splitX(topHalf, 0.5)

    -- Fixed height bar at bottom of bottomHalf (20px tall)
    local bottomBar = NLay.constraint(bottomHalf, {bottom=0, top=bottomHalf:height()-20})

    -- Centered box inside bottomHalf with 50px margins
    local centeredBox = NLay.constraint(bottomHalf, {left=50, right=50, top=50, bottom=50})

    layoutBoxes = {
        {box = root,     color = {0.2, 0.2, 0.2}},
        {box = padded,   color = {0.3, 0.3, 0.3}},
        {box = topHalf,  color = {0.5, 0.2, 0.2}},
        {box = bottomHalf, color = {0.2, 0.2, 0.5}},
        {box = leftTop,  color = {0.7, 0.4, 0.4}},
        {box = rightTop, color = {0.4, 0.7, 0.4}},
        {box = bottomBar, color = {0.8, 0.8, 0.3}},
        {box = centeredBox, color = {0.5, 0.5, 1.0}},
    }
end

function love.draw()
    for _, b in ipairs(layoutBoxes) do
        local x, y, w, h = b.box:unpack()
        love.graphics.setColor(b.color)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", x, y, w, h)
    end
end
