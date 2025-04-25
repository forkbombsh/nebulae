local element = require("ui.element")
local shared = require("ui.shared")
local group = element:extend()

function group:new(args)
    local b = element.new(self, args) -- Call the parent constructor

    b.elements = {}

    return b
end

function group:add(element)
    element.group = self
end

function group:remove(element)
    if element.parent ~= self or element.childID == nil then
        return
    end
    self.elements[element.childID] = nil
    element.group = nil
end

function group:addElements(...)
    for _, element in pairs({...}) do
        self:add(element)
    end
end

function group:removeElements(...)
    for _, element in pairs({...}) do
        self:remove(element)
    end
end

function group:removeAll()
    for id, element in pairs(self.elements) do
        self:remove(element)
    end
end

return group