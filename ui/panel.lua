local element = require("ui.element") -- Import the base class
local shared = require("ui.shared")

local panel = element:extend() -- Extend element

function panel:new(args)
    local b = element.new(self, args) -- Call the parent constructor

    b.elements = {}
    b.basedPos = args.basedPos or true

    b.scrollYOffset = args.scrollYOffset or 0
    b.scrollYSize = args.scrollYSize or 20

    if type(args.invertedScrolling) == "boolean" then
        b.invertedScrolling = args.invertedScrolling
    else
        b.invertedScrolling = false
    end

    b.isOpen = true

    return b
end

function panel:add(element)
    element.parent = self
    element.childID = shared.getUniqueID()
    element._.oldMainDraw = element.mainDraw
    element.mainDraw = false
    if element.addedToPanel then
        element:addedToPanel()
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
    if element.removedFromPanel then
        element:removedFromPanel()
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

function panel:removeAll()
    for id, element in pairs(self.elements) do
        self:remove(element)
    end
end

function panel:draw()
    self:baseDraw() -- Call the parent class drawing logic

    self:applyStencilMask(function()
        for _, element in pairs(self.elements) do
            if element.draw and not element.mainDraw then
                element:draw()
            end
        end
    end)
end

function panel:update(dt)
    for _, element in pairs(self.elements) do
        if element.update then
            element:update(dt)
        end
        if self.basedPos then
            element.x = self.x + element.bx
            element.y = self.y + element.by + self.scrollYOffset
        end
    end
end

function panel:sendEvent(name, ...)
    for _, element in pairs(self.elements) do
        local func = element[name]
        if type(func) == "function" then
            func(element, ...) -- Directly call the event on the child element
        end
    end
end

function panel:sendEventSelf(name, ...)
    for _, element in pairs(self.elements) do
        local func = element[name]
        if type(func) == "function" then
            func(element, ...) -- Call on the element itself without parent looping
        end
    end
end

function panel:wheelmoved(dx, dy)
    if self:isMouseInside() then
        self.scrollYOffset = self.scrollYOffset + dy * self.scrollYSize * (self.invertedScrolling and -1 or 1)
    end
end

return panel
