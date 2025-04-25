local timeline = {
    height = 200,
    layersVisibleAmt = 5,
    zoom = 1
}
local beach = love.graphics.newImage("assets/images/placeholderbeach.jpg")

local randomSampleThings = {}

for i = 1, 300 do
    randomSampleThings[i] = love.math.random(-100, 100)
end

function timeline:draw()
    local font = love.graphics.getFont()
    local zoom = self.zoom
    local layerHeight = self.height / self.layersVisibleAmt
    for i = 1, self.layersVisibleAmt do
        local y = love.graphics.getHeight() - i / self.layersVisibleAmt * self.height
        love.graphics.line(0, y, love.graphics.getWidth(), y)
    end
    love.graphics.setColor(0.7, 1, 0.7)
    love.graphics.rectangle("fill", 100 * zoom, love.graphics.getHeight() - (layerHeight * 5), 300 * zoom, layerHeight)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("fill", 200 * zoom, love.graphics.getHeight() - (layerHeight * 4), 300 * zoom, layerHeight)
    love.graphics.rectangle("fill", 300 * zoom, love.graphics.getHeight() - (layerHeight * 3), 300 * zoom, layerHeight)
    love.graphics.setColor(0, 0, 0)
    for i = 1, #randomSampleThings do
        love.graphics.rectangle("fill", 100 * zoom + i,
            love.graphics.getHeight() - (layerHeight * 5) + (layerHeight / 2),
            1, (randomSampleThings[i] / 100) * (layerHeight / 2))
    end
    love.graphics.setColor(0, 0, 0, 0.5)
    local w, h = font:getWidth("Test.png"), font:getHeight()
    love.graphics.rectangle("fill", 100 * zoom, love.graphics.getHeight() - (layerHeight * 5), w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Test.wav", 100 * zoom, love.graphics.getHeight() - (layerHeight * 5))
    local relScaleImageW, relScaleImageH = RelativeScale(beach:getWidth(), beach:getHeight(), 300 * zoom, layerHeight)
    love.graphics.draw(beach, 200 * zoom, love.graphics.getHeight() - (layerHeight * 4), 0, relScaleImageW,
        relScaleImageH)
    local w, h = font:getWidth("Test.png"), font:getHeight()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 200 * zoom, love.graphics.getHeight() - (layerHeight * 4), w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Test.png", 200 * zoom, love.graphics.getHeight() - (layerHeight * 4))
    love.graphics.setColor(0, 0, 0)
end

return timeline
