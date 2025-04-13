-- Base element code
local element = {}

element.__index = element

-- Create a new element and initialize it
function element:new(args)
    local b = setmetatable({}, self)

    -- Default properties
    b._ = {}

    -- Set properties
    b.x = args.x or 0
    b.y = args.y or 0
    b.width = args.width or 100
    b.height = args.height or 200

    b.bx = args.bx or b.x
    b.by = args.by or b.y

    b.backgroundColor = args.backgroundColor or { 0.5, 0.5, 0.5 }
    b._.curbackgroundColor = b.backgroundColor

    b.borderColor = args.borderColor or { 1, 1, 1, 0 }
    b._.curBorderColor = b.borderColor

    b.borderRadius = args.borderRadius or 0
    b.borderThickness = args.borderThickness or 1

    b.lineStyle = "rough"

    if type(args.hasBackground) == "boolean" then
        b.hasBackground = args.hasBackground
    else
        b.hasBackground = true
    end

    if type(args.mainDraw) == "boolean" then
        b.mainDraw = args.mainDraw
    else
        b.mainDraw = true
    end

    if type(args.disabled) == "boolean" then
        b.disabled = args.disabled
    else
        b.disabled = false
    end

    return b
end

function element:isMouseInside()
    local mx, my = love.mouse.getPosition()
    return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
end

-- Base draw function
function element:baseDraw()
    if self.hasBackground then
        local lineStyle = love.graphics.getLineStyle()
        love.graphics.setLineStyle(self.lineStyle)
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(self._.curbackgroundColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.borderRadius)

        if self.borderRadius > 0 and (self.borderColor[4] ~= nil and (self.borderColor[4] < 1)) then
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, self.borderRadius)
        end

        local lineWidth = love.graphics.getLineWidth()
        love.graphics.setLineWidth(self.borderThickness)
        love.graphics.setColor(self._.curBorderColor)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, self.borderRadius)
        love.graphics.setLineWidth(lineWidth)
        love.graphics.setLineStyle(lineStyle)
        if self.disabled then
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.borderRadius)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height, self.borderRadius)
        end
        love.graphics.setColor(r, g, b, a)
    end
end

-- Draw function that calls base draw
function element:draw()
    self:baseDraw()
end

function element:getStencilMask()
    return function()
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.borderRadius)
    end
end

function element:applyStencilMask(func)
    love.graphics.stencil(self:getStencilMask(), "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    func()
    love.graphics.setStencilTest()
end

-- Extend function to create subclasses
function element:extend()
    local cls = {}
    for k, v in pairs(self) do cls[k] = v end
    cls.__index = cls
    setmetatable(cls, self)
    return cls
end

return element
