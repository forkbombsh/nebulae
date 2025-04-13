local element = require("ui.element") -- Import the base class

local label = element:extend()        -- Extend element

function label:new(args)
    local b = element.new(self, args) -- Call the parent constructor

    b.textColor = args.textColor or { 1, 1, 1 }
    b.text = args.text or "Label"
    if type(args.wrapText) == "boolean" then
        b.wrapText = args.wrapText
    else
        b.wrapText = true
    end

    b.font = args.font or love.graphics.getFont()

    local font = b.font
    if args.wrapText then
        local breakAmt = select(2, b.text:gsub("\n", "\n")) + 1
        b.width = args.width or font:getWidth(b.text) * 3
        b.height = args.height or (font:getHeight() * breakAmt) * 2
    else
        b.width = args.width or font:getWidth(b.text) * 3
        b.height = args.height or font:getHeight() * 2
    end

    return b
end

function label:draw()
    self:baseDraw() -- Call the parent class drawing logic

    local r, g, b, a = love.graphics.getColor()

    local font = self.font
    local textHeight = font:getHeight()

    love.graphics.setColor(self.textColor)
    if self.disabled then
        local rd2, gd2, bd2 = love.graphics.getColor()
        rd2, gd2, bd2 = rd2 * 0.3, gd2 * 0.3, bd2 * 0.3
        love.graphics.setColor(rd2, gd2, bd2)
    end
    self:applyStencilMask(function()
        if self.wrapText then
            local width, wrappedText = font:getWrap(self.text, self.width)
            local yOffset = math.floor(self.y + (self.height - #wrappedText * textHeight) / 2)
            for i, line in ipairs(wrappedText) do
                love.graphics.print(line, self.font, math.floor(self.x + (self.width - font:getWidth(line)) / 2),
                    yOffset + (i - 1) * textHeight)
            end
        else
            local textWidth = font:getWidth(self.text)
            love.graphics.print(self.text, self.font, math.floor(self.x + (self.width - textWidth) / 2),
                math.floor(self.y + (self.height - textHeight) / 2))
        end
    end)
    love.graphics.setColor(r, g, b, a)
end

return label
