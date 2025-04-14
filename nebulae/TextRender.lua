TextRender = Class("TextRender")

local cachedFonts = {}
local curTexts = {}

-- Font caching method
function TextRender:getFont(font, quality)
    local cachedFont
    if font and font.typeOf then
        cachedFont = font
    else
        local str = tostring(font) .. tostring(quality)
        cachedFont = cachedFonts[str]
        if not cachedFont then
            -- Create new font
            cachedFont = font and love.graphics.newFont(font, quality) or love.graphics.newFont(quality)
            cachedFonts[str] = cachedFont
        end
    end
    return cachedFont
end

-- Initialization
function TextRender:initialize(text, x, y, size, quality, spacing, font, project)
    x = x or 0
    y = y or 0
    quality = quality or 20
    size = size or 20
    spacing = spacing or 0
    self.x = x
    self.y = y
    self.quality = quality
    self.size = size
    self.font = self:getFont(font, quality)
    self.spacing = spacing
    self.project = project
    self:setText(text)
    table.insert(curTexts, self) -- Register instance for global update
    print("new text object")
end

function TextRender:setText(text)
    self.text = text
end

-- Draw method
function TextRender:draw()
    if not self.segments then return end

    local scaleFactor = self.size / self.quality
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(scaleFactor)
    local xOffset = 0
    local yOffset = 0
    for i = 1, #self.text do
        local char = string.char(self.text:byte(i))
        love.graphics.print(char, self.font, xOffset, yOffset)
        xOffset = xOffset + self.font:getWidth(char)
        if char == "\n" then
            xOffset = 0
            yOffset = yOffset + self.font:getHeight()
        end
    end
    love.graphics.pop()
end
