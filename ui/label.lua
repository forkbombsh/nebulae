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
    b.dynamicFontSize = args.dynamicFontSize or false

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

function label:updateLayoutCache()
    if self._cachedText ~= self.text or self._cachedWidth ~= self.width or self._cachedFont ~= self.font or self._cachedDynamicFontSize ~= self.dynamicFontSize then
        self._cachedText = self.text
        self._cachedFont = self.font
        self._cachedWidth = self.width
        self._cachedDynamicFontSize = self.dynamicFontSize

        if self.dynamicFontSize then
            -- Dynamically adjust font size based on the label's width and height
            local fontSize = self.font:getHeight()
            local newFont = self.font
            local desiredWidth = self.width * 0.9 -- Padding margin
            local desiredHeight = self.height * 0.9

            local size = fontSize
            -- Try reducing font size to fit
            while (newFont:getWidth(self.text) > desiredWidth or newFont:getHeight() > desiredHeight) and size > 5 do
                size = size - 1
                newFont = love.graphics.newFont(self.font:getFamily(), size)
            end
            self._dynamicFont = newFont
        else
            self._dynamicFont = self.font
        end

        if self.wrapText then
            local _, lines = self._dynamicFont:getWrap(self.text, self.width)
            self._cachedWrappedText = lines
        else
            self._cachedWrappedText = nil
        end
    end
end

function label:draw()
    self:baseDraw()
    self:updateLayoutCache()

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(self.textColor)

    local font = self._dynamicFont or self.font
    local textHeight = font:getHeight()

    if self.disabled then
        local rd2, gd2, bd2 = love.graphics.getColor()
        love.graphics.setColor(rd2 * 0.3, gd2 * 0.3, bd2 * 0.3)
    end

    if self.wrapText and self._cachedWrappedText then
        local yOffset = math.floor(self.y + (self.height - #self._cachedWrappedText * textHeight) / 2)
        for i, line in ipairs(self._cachedWrappedText) do
            love.graphics.print(line, font,
                math.floor(self.x + (self.width - font:getWidth(line)) / 2),
                yOffset + (i - 1) * textHeight)
        end
    else
        local textWidth = font:getWidth(self.text)
        love.graphics.print(self.text, font,
            math.floor(self.x + (self.width - textWidth) / 2),
            math.floor(self.y + (self.height - textHeight) / 2))
    end

    love.graphics.setColor(r, g, b, a)
end

return label
