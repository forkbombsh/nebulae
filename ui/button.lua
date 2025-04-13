local element = require("ui.element") -- Import the base class
local shared = require("ui.shared")
local ui = shared.ui

local button = element:extend() -- Extend element

function button:new(args)
    local b = element.new(self, args) -- Call the parent constructor

    b.text = args.text or "Button"

    local font = love.graphics.getFont()
    if args.wrapText then
        local breakAmt = select(2, b.text:gsub("\n", "\n")) + 1
        b.width = args.width or font:getWidth(b.text) * 3
        b.height = args.height or (font:getHeight() * breakAmt) * 2
    else
        b.width = args.width or font:getWidth(b.text) * 3
        b.height = args.height or font:getHeight() * 2
    end

    b.backgroundColorHover = args.backgroundColorHover or { 0.6, 0.6, 0.6 }
    b.backgroundColorPress = args.backgroundColorPress or { 0.4, 0.4, 0.4 }

    b.textColor = args.textColor or { 1, 1, 1 }
    b.textColorHover = args.textColorHover or b.textColor
    b.textColorPress = args.textColorPress or b.textColor

    b.borderColorHover = args.borderColorHover or b.borderColor
    b.borderColorPress = args.borderColorPress or b.borderColor

    b._.curTextColor = b.textColor

    b.wrapText = args.wrapText ~= true
    b.hasText = args.hasText ~= true

    b.image = args.image
    b.imageTransformation = {
        translation = { 0, 0 },
        scale = { 1, 1 },
        origin = { 0, 0 },
        rotation = 0,
    }

    b.onPress = args.onPress or function(_, _) end
    b.onRelease = args.onRelease or function(_, _) end
    b.onHover = args.onHover or function(_, _) end
    b.onUnhover = args.onUnhover or function(_, _) end
    b.onHoverChange = args.onHoverChange or function(_, _) end

    b.isHovering = false
    b.isPressed = false
    b._.isHoveringOld = false
    b._.isPressedOld = false
    b._.waitForRelease = false

    b.button = args.button or 1

    b.hoverOnly = args.hoverOnly

    b.textLabel = ui.new("label", {
        text = b.text,
        font = args.font,
        wrapText = b.wrapText,
        textColor = b.textColor,
        x = b.x,
        y = b.y,
        width = b.width,
        height = b.height,
        hasBackground = false,
        mainDraw = false
    })

    b.addables = {
        b.textLabel
    }

    return b
end

function button:draw()
    self:baseDraw() -- Call the parent class drawing logic

    local r, g, b, a = love.graphics.getColor()

    if self.hasText then
        love.graphics.setColor(self._.curTextColor)

        self.textLabel:draw()
    end
    local image = self.image
    if image and image.typeOf and image:typeOf("Texture") then
        local x, y = unpack(self.imageTransformation.translation)
        local sx, sy = unpack(self.imageTransformation.scale)
        local ox, oy = unpack(self.imageTransformation.origin)
        local rotation = self.imageTransformation.rotation
        love.graphics.draw(image, self.x + x, self.y + y, rotation, sx, sy, ox, oy)
    end

    love.graphics.setColor(r, g, b, a)
end

function button:update(dt)
    self.textLabel.text = self.text
    self.textLabel.wrapText = self.wrapText
    self.textLabel.x = self.x
    self.textLabel.y = self.y
    self.textLabel.width = self.width
    self.textLabel.height = self.height
    self.textLabel.isInButton = self
    self.textLabel.disabled = self.disabled
end

function button:mousemoved(x, y, dx, dy)
    self.isHovering = self:isOver(x, y)
    if self._.isHoveringOld ~= self.isHovering then
        if self.isHovering then
            self._.curbackgroundColor = self.backgroundColorHover
            self._.curTextColor = self.textColorHover
            self._.curBorderColor = self.borderColorHover
            self:onHover()
        else
            if self.isPressed then
                self._.waitForRelease = true
            else
                self._.curbackgroundColor = self.backgroundColor
                self._.curTextColor = self.textColor
                self._.curBorderColor = self.borderColor
            end
            self:onUnhover()
        end
        self:onHoverChange(self.isHovering)
        self._.isHoveringOld = self.isHovering
    end
end

function button:isOver(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function button:mousepressed(x, y, b)
    if not self.hoverOnly and self:isOver(x, y) and b == self.button then
        self:onPress(b)
        self.isPressed = true
        self._.curbackgroundColor = self.backgroundColorPress
        self._.curTextColor = self.textColorPress
        self._.curBorderColor = self.borderColorPress
    end
end

function button:mousereleased(x, y, b)
    if not self.hoverOnly and self.isPressed and b == self.button then
        self:onRelease(b)
        self.isPressed = false
        if self.isHovering then
            self._.curbackgroundColor = self.backgroundColorHover
            self._.curTextColor = self.textColorHover
            self._.curBorderColor = self.borderColorHover
        else
            self._.curbackgroundColor = self.backgroundColor
            self._.curTextColor = self.textColor
            self._.curBorderColor = self.borderColor
        end
    end
end

function button:centerImageWithTranslation()
    local image = self.image
    if image and image.typeOf and image:typeOf("Texture") then
        self.imageTransformation.translation = { self.x + ((self.width / 2) - (image:getWidth() / 2)), self.y +
        ((self.height / 2) - (image:getHeight() / 2)) }
    end
end

function button:centerImageWithOrigin()
    local image = self.image
    if image and image.typeOf and image:typeOf("Texture") then
        self.imageTransformation.origin = { image:getWidth() / 2, image:getHeight() / 2 }
        self.imageTransformation.translation = { self.x + self.width / 2, self.y + self.height / 2 }
    end
end

return button
