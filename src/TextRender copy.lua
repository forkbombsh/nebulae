local textRender = Class("TextRender")
local updatedTime = 0
local function getTime()
    return updatedTime
end

local safeEnv = {
    math = math, -- Allow math functions
    getAppTime = getTime,
    random = love.math.random,
    getAppWidth = love.graphics.getWidth,
    getAppHeight = love.graphics.getHeight,
    getProjectWidth = function()
        return 1280
    end,
    getProjectHeight = function()
        return 720
    end
}

local function executeInSandbox(code)
    -- Load the code into a function
    local func, err = load(code)

    if not func then
        return "Error loading code: " .. err
    end

    -- Set the environment for the function to be the safe environment
    setfenv(func, safeEnv)

    -- Execute the function with error handling
    local success, result = pcall(func)
    if success then
        return result
    else
        return "Error executing code: " .. result
    end
end

local cachedFonts = {}
local curTexts = {}

local function parseHTML(input)
    input = input:gsub("\n", "<br/>")
    local root = { type = "root", children = {} }
    local stack = { { node = root, contentStart = 1 } } -- Track content start position
    local pos = 1
    local len = #input

    local function parseTag(s, start)
        local tagEnd = s:find(">", start)
        if not tagEnd then return nil, nil end

        local tagContent = s:sub(start + 1, tagEnd - 1)
        local isClosing = tagContent:sub(1, 1) == "/"

        if isClosing then
            local tagName = tagContent:match("^/(%S+)")
            return tagEnd, { isClosing = true, name = tagName }
        else
            local isSelfClosing = tagContent:sub(-1) == "/"
            if isSelfClosing then
                tagContent = tagContent:sub(1, -2)
            end

            local tagName, attributes = tagContent:match("^(%S+)(.*)")
            local attrList = {}

            -- Parse attributes with more robust pattern
            for name, value in tagContent:gmatch('([%w-]+)%s*=%s*"([^"]*)"') do
                attrList[name] = value
            end

            return tagEnd, {
                isClosing = false,
                name = tagName,
                attributes = attrList,
                isSelfClosing = isSelfClosing
            }
        end
    end

    while pos <= len do
        local tagStart = input:find("<", pos)
        if not tagStart then
            -- Add remaining text
            local text = input:sub(pos)
            if #text > 0 then
                table.insert(stack[#stack].node.children, {
                    type = "text",
                    content = text
                })
            end
            break
        end

        -- Add text before tag
        local text = input:sub(pos, tagStart - 1)
        if #text > 0 then
            table.insert(stack[#stack].node.children, {
                type = "text",
                content = text
            })
        end

        -- Parse the tag
        local tagEnd, tagInfo = parseTag(input, tagStart)
        if not tagEnd then break end

        if tagInfo.isClosing then
            -- Handle closing tag
            if #stack > 1 and stack[#stack].node.name == tagInfo.name then
                -- Capture pureContent between opening and closing tags
                stack[#stack].node.pureContent = input:sub(
                    stack[#stack].contentStart,
                    tagStart - 1
                )
                table.remove(stack) -- Pop from stack
            end
        else
            -- Create new tag node
            local newNode = {
                type = "tag",
                name = tagInfo.name,
                attributes = tagInfo.attributes,
                children = {},
                pureContent = ""
            }

            -- Add to current parent's children
            table.insert(stack[#stack].node.children, newNode)

            if not tagInfo.isSelfClosing then
                -- Push to stack with content start position
                table.insert(stack, {
                    node = newNode,
                    contentStart = tagEnd + 1
                })
            else
                newNode.pureContent = ""
            end
        end

        pos = tagEnd + 1
    end

    return root.children
end

-- Font caching method
function textRender:getFont(font, quality)
    local cachedFont
    if font and font.typeOf then
        cachedFont = font
    else
        local str = tostring(font) .. tostring(quality)
        local cachedFont = cachedFonts[str]
        if not cachedFont then
            -- Create new font
            cachedFont = font and love.graphics.newFont(font, quality) or love.graphics.newFont(quality)
            cachedFonts[str] = cachedFont
        end
    end
    return cachedFont
end

-- Initialization
function textRender:initialize(text, x, y, size, quality, spacing, font, project)
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

-- Set text and parse
function textRender:setText(text)
    self.segments = parseHTML(text)
end

function textRender:applyTranslations(tagStack, charIndex, textContent)
    local scaleFactor = self.quality / self.size
    local dx = 0
    local dy = 0
    local currentHue = nil
    local baseColor = { 1, 1, 1, 1 } -- Default white

    -- Process all active tags in reverse order (innermost first)
    for i = #tagStack, 1, -1 do
        local tag = tagStack[i]

        safeEnv.charIndex = charIndex

        -- Rainbow effect
        if tag.name == "rainbow" then
            local freq = (tag.attributes.freq or 1)
            local t = updatedTime + charIndex * 0.1
            r, g, b = math.sin(t * freq) * 0.5 + 0.5, math.sin((t * freq) + 2) * 0.5 + 0.5,
                math.sin((t * freq) + 4) * 0.5 + 0.5
            baseColor = { r, g, b }
        end

        -- Wave effect
        if tag.name == "wave" then
            local amplitude = tag.attributes.amplitude or 1
            local speed = tag.attributes.speed or 1
            dy = dy + math.sin(updatedTime * (5 + (speed)) + charIndex * 0.3) *
                (5 * (amplitude)) * scaleFactor
        end

        -- Shake effect (example of combined position offsets)
        if tag.name == "shake" then
            local amplitudeX = tag.attributes.amplitudeX or 2
            local amplitudeY = tag.attributes.amplitudeY or 1
            local amplitude = tag.attributes.amplitude or 1
            amplitudeX = amplitudeX + amplitude
            amplitudeY = amplitudeY + amplitude
            dx = dx + love.math.random(-amplitudeX, amplitudeX)
            dy = dy + love.math.random(-amplitudeY, amplitudeY)
        end

        if tag.name == "marquee" then
            local speed = tag.attributes.speed and tonumber(tag.attributes.speed) or 100
            local space = tag.attributes.space and tonumber(tag.attributes.space) or 20
            -- local duration = updatedTime - (tag.startTime or 0)
            local marqueeOffset = 0

            -- Calculate offset based on direction
            marqueeOffset = (updatedTime * speed) % ((self.font:getWidth(textContent) / scaleFactor) + space)

            dx = dx + marqueeOffset
        end

        if tag.name == "funcPerChar" then
            local attributes = tag.attributes
            local x, y = executeInSandbox(attributes.x or "return 0"), executeInSandbox(attributes.y or "return 0")
            local r = executeInSandbox(attributes.r or "return 1")
            local g = executeInSandbox(attributes.g or "return 1")
            local b = executeInSandbox(attributes.b or "return 1")
            local a = executeInSandbox(attributes.a or "return 1")
            baseColor = { r, g, b, a }
            dx = dx + x
            dy = dy + y
        end

        if tag.name == "func" then
            local attributes = tag.attributes
            local x, y = executeInSandbox(attributes.x or "return 0"), executeInSandbox(attributes.y or "return 0")
            local r = executeInSandbox(attributes.r or "return 1")
            local g = executeInSandbox(attributes.g or "return 1")
            local b = executeInSandbox(attributes.b or "return 1")
            local a = executeInSandbox(attributes.a or "return 1")
            baseColor = { r, g, b, a }
            dx = dx + x
            dy = dy + y
        end
    end

    return dx, dy, baseColor
end

-- Draw method
function textRender:draw()
    local r, g, b, a = love.graphics.getColor()
    if not self.segments then return end

    local scaleFactor = self.size / self.quality
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(scaleFactor)

    local baseX = 0
    local baseY = 0
    local tagStack = {} -- Track active tags for nested effects
    local curCharIndex = 0

    local function renderNode(node, x, y)
        local currentX = x
        local currentY = y

        for _, element in ipairs(node) do
            if element.type == "text" then
                -- Render text with current tag effects
                local function draw(ox, oy)
                    for i = 1, #element.content do
                        local char = element.content:sub(i, i)
                        curCharIndex = curCharIndex + 1
                        local dx, dy, color = self:applyTranslations(tagStack, curCharIndex, element.content)
                        love.graphics.setColor(color)
                        love.graphics.print(
                            char,
                            self.font,
                            (currentX + dx + ox) * scaleFactor,
                            (currentY + dy + oy) * scaleFactor
                        )
                        currentX = currentX + (self.font:getWidth(char) / scaleFactor) + self.spacing
                    end
                end
                local isMarquee = #tagStack > 0 and tagStack[#tagStack].name == "marquee"
                local space = 0
                if isMarquee then
                    local marqueeTag = tagStack[#tagStack]
                    space = marqueeTag.attributes.space and tonumber(marqueeTag.attributes.space) or 20
                    love.graphics.setScissor(self.x, self.y,
                        self.font:getWidth(element.content) / scaleFactor, self.font:getHeight() / scaleFactor)
                end
                draw(0, 0)
                if isMarquee then
                    draw((-(self.font:getWidth(element.content) / scaleFactor) * 2) - space, 0)
                    draw(
                        ((self.font:getWidth(element.content) / scaleFactor) -
                            ((self.font:getWidth(element.content) / scaleFactor) * 2)) + space, 0)
                    love.graphics.setScissor()
                end
            elseif element.type == "tag" then
                -- Handle opening tag
                local tagData = {
                    name = element.name,
                    attributes = element.attributes,
                    startX = currentX,
                    startY = currentY,
                    startTime = updatedTime -- Track start time for marquee
                }
                table.insert(tagStack, tagData)

                -- Handle special tags
                if element.name == "br" then
                    currentX = 0
                    currentY = currentY + self.font:getHeight() / scaleFactor
                end

                -- Render children
                if #element.children > 0 then
                    currentX, currentY = renderNode(element.children, currentX, currentY)
                end

                -- Handle closing tag
                if element.name ~= "br" then
                    table.remove(tagStack)
                end
            end
        end

        return currentX, currentY -- Return updated position
    end

    renderNode(self.segments, baseX, baseY)
    love.graphics.pop()
    love.graphics.setColor(r, g, b, a)
end

-- Individual update function
function textRender:update(dt, ut)
    if ut then
        updatedTime = ut
    else
        updatedTime = love.timer.getTime()
    end
    if self.project then
        safeEnv.getProjectWidth = function()
            return self.project.width
        end
        safeEnv.getProjectHeight = function()
            return self.project.height
        end
    end
end

-- Update all instances of TextRender
function textRender:updateAll(dt)
    for _, text in ipairs(curTexts) do
        text:update(dt)
    end
end

-- Return the class
return textRender
