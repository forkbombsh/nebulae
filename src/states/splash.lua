local state = {
    timer = 0.5
}
local nebulaeLetter = love.graphics.newImage("assets/logo/nebulae-letter-circle.png")

function state:enter()
    love.mouse.setCursor(love.mouse.getSystemCursor("wait"))
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
end

function state:draw()
    love.graphics.setColor(1, 1, 1, 1 - (state.timer / 0.5))
    local reset = ApplyLetterbox(nebulaeLetter:getWidth(), nebulaeLetter:getHeight() * 2)
    love.graphics.draw(nebulaeLetter, 0, ((nebulaeLetter:getHeight() * 2) / 2) - ((nebulaeLetter:getHeight() * 2) / 4))
    reset()
end

function state:update(dt)
    self.timer = self.timer - dt
    if self.timer < 0 then
        StateManager.switch("menu")
        self.timer = 1
    end
end

function state:leave()
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
end

return state
