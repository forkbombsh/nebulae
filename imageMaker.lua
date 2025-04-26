local fontname = "assets/fonts/Jellee-Roman.otf"
local font = love.graphics.newFont(fontname, 300)
local font2 = love.graphics.newFont(fontname, 1000)

local swirl_shader = love.graphics.newShader([[
    extern float time;  // To animate the swirl
    extern vec2 center;  // Center of the swirl
    extern float strength;  // How strong the swirl effect is

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
    {
        // Calculate the distance from the center
        vec2 delta = texture_coords - center;
        float dist = length(delta);

        // Apply the swirl based on distance and time
        float angle = atan(delta.y, delta.x) + sin(dist * 10.0 + time) * strength;
        float radius = dist;

        // Get the new texture coordinates
        vec2 new_coords = center + vec2(cos(angle), sin(angle)) * radius;

        // Sample the texture at the new coordinates
        vec4 texColor = Texel(texture, new_coords);
        return texColor * color;
    }
]])

local drawn = {}

local draw = {
    function()
        return function(w, h)
            for i = 1, 1500 do
                love.graphics.setColor(1, 1, 1, love.math.random())
                local x, y = love.math.random(0, 2000), love.math.random(0, 2000)
                local size = love.math.random() * 2
                love.graphics.circle("fill", x, y, size)
            end
        end, "stars.png", 2000, 2000
    end,
    function()
        return function(w, h)
            -- Send static values (or dynamic ones) for the shader
            swirl_shader:send("time", 234324)         -- Static time value
            swirl_shader:send("strength", 1)
            swirl_shader:send("center", { 0.5, 0.5 }) -- Center of the swirl (no need for mouse position)
            -- Create gradient canvas
            local gradientCanvas = love.graphics.newCanvas(w, h)
            gradientCanvas:renderTo(function()
                for y = 0, h do
                    love.graphics.setColor(0, 0, (y / h) * 0.2)
                    love.graphics.rectangle("fill", 0, y, w, 1)
                end
            end)

            -- Apply shader and draw the gradient canvas
            love.graphics.setColor(1, 1, 1)
            love.graphics.setShader(swirl_shader)
            love.graphics.draw(gradientCanvas, 0, 0)
            love.graphics.setShader()
        end, "grad.png", 2000, 2000
    end,
    function()
        return function(w, h)
            love.graphics.draw(drawn["grad.png"])
            love.graphics.draw(drawn["stars.png"])
        end, "stars-grad.png", 2000, 2000
    end,
    function()
        return function(w, h)
            love.graphics.draw(drawn["stars-grad.png"])

            -- Draw text
            local text = "Nebulae"
            love.graphics.print(text, font, w / 2 - font:getWidth(text) / 2, (h / 2 - font:getHeight() / 2))
        end, "nebulae.png", 2000, 2000
    end,
    function()
        return function(w, h)
            love.graphics.draw(drawn["stars-grad.png"])

            -- Draw text
            local text = "N"
            love.graphics.print(text, font2, w / 2 - font2:getWidth(text) / 2, (h / 2 - font2:getHeight() / 2))
        end, "nebulae-letter.png", 2000, 2000
    end,
    function()
        return function()
            love.graphics.setColorMask(false)
            love.graphics.setStencilMode("draw", 1)
            love.graphics.circle("fill", 1000, 1000, 1000)
            love.graphics.setStencilMode("test", 1)
            love.graphics.setColorMask(true)
            love.graphics.draw(drawn["nebulae.png"], 0, 0)
            love.graphics.setStencilMode()
        end, "nebulae-circle.png", 2000, 2000
    end,
    function()
        return function()
            love.graphics.setColorMask(false)
            love.graphics.setStencilMode("draw", 1)
            love.graphics.circle("fill", 1000, 1000, 1000)
            love.graphics.setStencilMode("test", 1)
            love.graphics.setColorMask(true)
            love.graphics.draw(drawn["nebulae-letter.png"], 0, 0)
            love.graphics.setStencilMode()
        end, "nebulae-letter-circle.png", 2000, 2000
    end,
    function()
        return function()
            love.graphics.setColorMask(false)
            love.graphics.setStencilMode("draw", 1)
            love.graphics.circle("fill", 1000, 1000, 1000)
            love.graphics.setStencilMode("test", 1)
            love.graphics.setColorMask(true)
            love.graphics.draw(drawn["grad.png"], 0, 0)
            love.graphics.setStencilMode()
        end, "grad-circle.png", 2000, 2000
    end,
    function()
        return function()
            love.graphics.setColorMask(false)
            love.graphics.setStencilMode("draw", 1)
            love.graphics.circle("fill", 1000, 1000, 1000)
            love.graphics.setStencilMode("test", 1)
            love.graphics.setColorMask(true)
            love.graphics.draw(drawn["stars-grad.png"], 0, 0)
            love.graphics.setStencilMode()
        end, "stars-grad-circle.png", 2000, 2000
    end
}

-- Below doesn't matter

love.graphics.setLineStyle("rough") -- Disables smoothing.

for i, v in ipairs(draw) do
    local draw, name, w, h = v()
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas({ canvas, stencil = true })
    love.graphics.clear()
    love.graphics.origin()
    draw(w, h)
    love.graphics.setCanvas()

    drawn[name] = canvas

    local imgdata = love.graphics.readbackTexture(canvas)
    imgdata:encode("png", name)
end

love.event.quit()
