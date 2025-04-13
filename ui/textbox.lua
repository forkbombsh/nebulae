local utf8 = require("utf8")
local element = require("ui.element")

local textbox = element:extend()

function textbox:new(args)
    local b = element.new(self, args)

    b.text = args.text or "Textbox"
    b.textColor = args.textColor or { 1, 1, 1 }
    b.textSize = args.textSize or 12

    b.isBlinkerOn = true
    b.blinkerTimer = 0
    b.blinkerSpeed = 0.5
    b.blinkerOffset = utf8.len(b.text) or 0

    b._.oldFocused = false
    b.isFocused = false
    b._.oldText = ""

    b.textMarginX = args.textMarginX or 0
    b.textMarginY = args.textMarginY or 0

    b.multiline = args.multiline ~= false -- default to true
    b.textLimit = args.textLimit or (b.multiline and 100 or 30)

    b.onTextChange = args.onTextChange or function(_, _) end

    b.font = args.font or love.graphics.getFont()

    b.blinker = "_"

    return b
end

function textbox:draw()
    local font = love.graphics.getFont()
    self:baseDraw()

    local _, wrappedText = font:getWrap(self.text, self.width - (self.textMarginX * 2))
    local lineHeight = font:getHeight()
    local y = self.y + 10 + self.textMarginY

    for _, line in ipairs(wrappedText) do
        love.graphics.print(line, self.font, self.x + 10 + self.textMarginX, y)
        y = y + lineHeight
    end

    if self.isBlinkerOn and self.isFocused then
        local byteOffset = utf8.offset(self.text, self.blinkerOffset + 1)
        local before = byteOffset and self.text:sub(1, byteOffset - 1) or self.text

        local _, blinkerLines = font:getWrap(before, self.width - (self.textMarginX * 2))
        local blinkerLine = blinkerLines[#blinkerLines] or ""
        local blinkerX = self.x + 10 + self.textMarginX + font:getWidth(blinkerLine)
        local blinkerY = self.y + 10 + self.textMarginY + (lineHeight * (#blinkerLines - 1))

        love.graphics.print(self.blinker, blinkerX + font:getWidth(self.blinker), blinkerY)
    end
end

function textbox:update(dt)
    self.blinkerTimer = self.blinkerTimer + dt
    if self.blinkerTimer >= self.blinkerSpeed then
        self.blinkerTimer = 0
        self.isBlinkerOn = not self.isBlinkerOn
    end

    if self.isFocused ~= self._.oldFocused then
        self._.oldFocused = self.isFocused
        self:visibliseBlinker()
        if self.isFocused then
            UI.kFocusNum = UI.kFocusNum + 1
            -- if UI.kFocusNum > 1 then
            --     UI.restartTextbox = true
            -- end
        else
            UI.kFocusNum = UI.kFocusNum - 1
        end
    end

    if self.text ~= self._.oldText then
        self._.oldText = self.text
        self.onTextChange(self, self.text)
    end
end

function textbox:visibliseBlinker()
    self.isBlinkerOn = true
    self.blinkerTimer = 0
end

function textbox:textinput(char)
    if utf8.len(self.text) >= self.textLimit or not self.isFocused then return end

    local byteOffset = utf8.offset(self.text, self.blinkerOffset + 1) or (#self.text + 1)
    self.text = self.text:sub(1, byteOffset - 1) .. char .. self.text:sub(byteOffset)
    self.blinkerOffset = self.blinkerOffset + 1
    self:visibliseBlinker()
end

function textbox:keypressed(key)
    if not self.isFocused then return end

    local len = utf8.len(self.text) or 0

    if key == "backspace" then
        if self.blinkerOffset > 0 then
            local byteStart = utf8.offset(self.text, self.blinkerOffset)
            local byteEnd = utf8.offset(self.text, self.blinkerOffset + 1) or (#self.text + 1)
            self.text = self.text:sub(1, byteStart - 1) .. self.text:sub(byteEnd)
            self.blinkerOffset = self.blinkerOffset - 1
            self:visibliseBlinker()
        end
    elseif key == "delete" then
        if self.blinkerOffset < len then
            local byteStart = utf8.offset(self.text, self.blinkerOffset + 1)
            local byteEnd = utf8.offset(self.text, self.blinkerOffset + 2) or (#self.text + 1)
            self.text = self.text:sub(1, byteStart - 1) .. self.text:sub(byteEnd)
            self:visibliseBlinker()
        end
    elseif key == "left" then
        self.blinkerOffset = math.max(0, self.blinkerOffset - 1)
        self:visibliseBlinker()
    elseif key == "right" then
        self.blinkerOffset = math.min(len, self.blinkerOffset + 1)
        self:visibliseBlinker()
    elseif (key == "return" or key == "kpenter") and self.multiline then
        self:textinput("\n")
    end
end

function textbox:mousepressed(x, y)
    self.isFocused = self:isMouseInside()
end

return textbox
