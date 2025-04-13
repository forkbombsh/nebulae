local element = require("ui.element") -- Import the base class
local shared = require("ui.shared")

local panel = element:extend() -- Extend element

function panel:new(args)
    local b = element.new(self, args) -- Call the parent constructor

    b.elements = {}
    b.basedPos = args.basedPos or true

    b.isOpen = true

    return b
end

function panel:add(element)
    element.parent = self
    element.childID = shared.getUniqueID()
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
            if element.draw then
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
            element.y = self.y + element.by
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

return panel
