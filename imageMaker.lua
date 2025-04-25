local draw = {
    function()
        love.graphics.line(0, 5, 11, 5)
        return "minimise.png", 11, 11
    end
}

-- Below doesnt matter

love.graphics.setLineStyle("rough") -- Disables smoothing.

for i, v in ipairs(draw) do
    local name, w, h = v()
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas({ canvas, stencil = true })
    love.graphics.clear()
    v()
    love.graphics.setCanvas()

    local imgdata = love.graphics.readbackTexture(canvas)
    imgdata:encode("png", name)
end

love.event.quit()
