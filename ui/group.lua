local element = require("ui.element")
local shared = require("ui.shared")
local group = element:extend()

function group:new(args)
    local b = element.new(self, args) -- Call the parent constructor

    b.elements = {}

    return b
end

function group:addElements(...)
    for _, element in pairs({...}) do
        self:add(element)
    end
end

return group