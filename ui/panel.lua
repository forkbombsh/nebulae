local element = require("ui.element") -- Import the base class
local shared = require("ui.shared")

local panel = element:extend() -- Extend element

function panel:new(args)
    local b = element.new(self, args) -- Call the parent constructor

    b.elements = {}
    b.basedPos = args.basedPos or true

    b.scrollSize = args.scrollSize or 20

    b.scrollYOffset = args.scrollYOffset or 0
    b.scrollXOffset = args.scrollXOffset or 0

    b.niceScrollXOffset = { b.scrollXOffset }
    b.niceScrollYOffset = { b.scrollYOffset }

    if type(args.niceScrolling) == "boolean" then
        b.niceScrolling = args.niceScrolling
    else
        b.niceScrolling = true
    end

    if type(args.niceScrollTime) == "number" then
        b.niceScrollTime = args.niceScrollTime
    else
        b.niceScrollTime = 0.2
    end

    if type(args.invertedXScrolling) == "boolean" then
        b.invertedXScrolling = args.invertedXScrolling
    else
        b.invertedXScrolling = false
    end

    if type(args.invertedYScrolling) == "boolean" then
        b.invertedYScrolling = args.invertedYScrolling
    else
        b.invertedYScrolling = false
    end

    b.maxScrollHeight = 0

    return b
end

function panel:getMaxYScroll()
    local maxY = 0
    for _, element in pairs(self.elements) do
        local bottom = element.by + (element.height or 0)
        if bottom > maxY then
            maxY = bottom
        end
    end
    local out = math.max(0, maxY - self.height)
    return out
end

function panel:getMaxXScroll()
    local maxX = 0
    for _, element in pairs(self.elements) do
        local right = element.bx + (element.width or 0)
        if right > maxX then
            maxX = right
        end
    end
    local out = math.max(0, maxX - self.width)
    return out
end

function panel:add(element)
    element.parent = self
    element.childID = shared.getUniqueID()
    element._.oldMainDraw = element.mainDraw
    element.mainDraw = false
    if type(element.addedToPanel) == "function" then
        element:addedToPanel()
    end
    if type(element.addables) == "table" then
        for i, v in ipairs(element.addables) do
            v._.addedByPanel = true
            self:add(v)
        end
        element._.addables = element.addables
    end
    if not shared.elements[element.id] then
        element.addedByPanel = true
        shared.ui.add(element)
    end
    self.elements[element.childID] = element
end

function panel:remove(element)
    if element.parent ~= self or element.childID == nil then
        return
    end
    if type(element.removedFromPanel) == "function" then
        element:removedFromPanel()
    end
    if type(element._.addables) == "table" then
        for i, v in ipairs(element._.addables) do
            v._.addedByPanel = nil
            self:remove(v)
        end
        element.addables = element._.addables
    end
    if element.addedByPanel then
        shared.ui.remove(element)
    end
    self.elements[element.childID] = nil
    element.parent = nil
    element.childID = nil
    if type(element._.oldMainDraw) == "boolean" then
        element.mainDraw = element._.oldMainDraw
    end
end

function panel:isChildVisible(a, b)
    return self:aabbCompare(a.x, a.y, a.width, a.height, b.x, b.y, b.width, b.height)
end

function panel:removeAll()
    for id, element in pairs(self.elements) do
        self:remove(element)
    end
end

function panel:draw()
    self:baseDraw() -- Call the parent class drawing logic

    self:applyStencilMask(function()
        for _, element in pairs(self.elements) do
            if element.draw and not element.mainDraw and self:isChildVisible(element, self) then
                element:draw()
            end
        end
    end)
end

function panel:update(dt)
    for _, element in pairs(self.elements) do
        if self:isChildVisible(element, self) then
            if element.update then
                element:update(dt)
            end
        end
        if self.basedPos then
            element.x = self.x + element.bx +
                (self.niceScrolling and self.niceScrollXOffset[1] or self.scrollXOffset)
            element.y = self.y + element.by +
                (self.niceScrolling and self.niceScrollYOffset[1] or self.scrollYOffset)
        end
    end
    self.maxYScroll = self:getMaxYScroll()
    self.maxXScroll = self:getMaxXScroll()
end

function panel:sendEvent(name, ...)
    for _, element in pairs(self.elements) do
        local func = element[name]
        if type(func) == "function" and self:isChildVisible(element, self) then
            func(...) -- Directly call the event on the child element
        end
    end
end

function panel:sendEventSelf(name, ...)
    for _, element in pairs(self.elements) do
        local func = element[name]
        if type(func) == "function" and self:isChildVisible(element, self) then
            func(element, ...) -- Call on the element itself without parent looping
        end
    end
end

function panel:wheelmoved(dx, dy)
    if self:isMouseInside() then
        self.scrollXOffset = self.scrollXOffset + dx * self.scrollSize * (self.invertedXScrolling and -1 or 1)
        self.scrollYOffset = self.scrollYOffset + dy * self.scrollSize * (self.invertedYScrolling and -1 or 1)
        if self.scrollXOffset > 0 then
            self.scrollXOffset = 0
        elseif self.scrollXOffset < -self.maxXScroll then
            self.scrollXOffset = -self.maxXScroll
        end
        if self.scrollYOffset > 0 then
            self.scrollYOffset = 0
        elseif self.scrollYOffset < -self.maxYScroll then
            self.scrollYOffset = -self.maxYScroll
        end
        Flux.to(self.niceScrollXOffset, self.niceScrollTime, {
            self.scrollXOffset
        }):ease("quartout")
        Flux.to(self.niceScrollYOffset, self.niceScrollTime, {
            self.scrollYOffset
        }):ease("quartout")
    end
end

return panel
