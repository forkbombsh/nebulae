local ui = {
    lineStyles = {
        rough = "rough",
        smooth = "smooth"
    },
    kFocusNum = 0,
    restartTextbox = false
}
local kFocusNumOld = 0
local elements = {}
local shared = require("ui.shared")
shared.ui = ui
shared.elements = elements

local wasJustRestartedTextbox = false

local types = {}

function ui.new(etype, args)
    if type(args) ~= "table" then
        args = {}
    end
    local elementType = types[etype]
    if not elementType then
        error("Invalid element type: " .. tostring(etype))
    end
    local element = elementType:new(args)
    element.id = shared.getUniqueID()
    element.z = args.z or 0 -- Default z-order value
    return element
end

function ui.markSortDirty()
    ui._needsSort = true
end

function ui.add(element)
    local id = element.id
    elements[id] = element
    if type(element.elements) == "table" then
        for _, child in pairs(element.elements) do
            if not ui.getElement(child.id) then
                ui.add(child)
            end
        end
    end
    if type(element.addables) == "table" then
        for _, child in pairs(element.addables) do
            if not ui.getElement(child.id) then
                ui.add(child)
            end
        end
    end
    if element.onAdded then
        element:onAdded()
    end
    if ui.curGroup then
        ui.curGroup:add(element)
    end
    ui.markSortDirty()
    return element
end

function ui.remove(element)
    if type(element.elements) == "table" then
        for _, child in pairs(element.elements) do
            ui.remove(child)
        end
    end
    if type(element.addables) == "table" then
        for _, child in pairs(element.addables) do
            ui.remove(child)
        end
    end
    if element.onRemoved then
        element:onRemoved()
    end
    if ui.curGroup then
        ui.curGroup:remove(element)
    end
    elements[element.id] = nil
    ui.markSortDirty()
end

function ui.addElements(...)
    for _, element in pairs({...}) do
        ui.add(element)
    end
end

function ui.removeElements(...)
    for _, element in pairs({...}) do
        ui.remove(element)
    end
end

function ui.addNew(etype, args)
    return ui.add(ui.new(etype, args))
end

function ui.getElement(id)
    return elements[id]
end

function ui.removeAll()
    for id, element in pairs(elements) do
        ui.remove(element)
    end
    ui.markSortDirty()
end

function ui.sendEvent(name, ...)
    for id, element in pairs(elements) do
        local func = element[name]
        if not element.disabled and type(func) == "function" then
            if element.parent then
                element.parent:sendEvent(name, ...)
            else
                func(...)
            end
        end
    end
end

function ui.sendEventSelf(name, ...)
    for id, element in pairs(elements) do
        local func = element[name]
        if not element.disabled and type(func) == "function" then
            if element.parent then
                element.parent:sendEventSelf(name, ...)
            else
                func(element, ...)
            end
        end
    end
end

function ui.update(dt)
    ui.sendEventSelf("update", dt)
    ui.keyboardFocused = ui.kFocusNum > 0
    if kFocusNumOld ~= ui.kFocusNum then
        kFocusNumOld = ui.kFocusNum
        if ui.kFocusNum > 0 then
            love.keyboard.setTextInput(true)
        else
            love.keyboard.setTextInput(false)
        end
    end
    if wasJustRestartedTextbox then
        wasJustRestartedTextbox = false
        love.keyboard.setTextInput(true)
    end
    if ui.restartTextbox then
        wasJustRestartedTextbox = true
        love.keyboard.setTextInput(false)
    end
end

function ui.draw()
    if ui._needsSort then
        ui._sortedElements = {}
        for _, element in pairs(elements) do
            table.insert(ui._sortedElements, element)
        end
        table.sort(ui._sortedElements, function(a, b) return a.z < b.z end)
        ui._needsSort = false
    end

    for _, element in ipairs(ui._sortedElements) do
        local func = element["draw"]
        if type(func) == "function" and not element.parent and element.mainDraw then
            func(element)
        end
    end
end

function ui.addElementType(name, element)
    element.name = name
    types[name] = element
end

function ui.removeElementType(name)
    types[name] = nil
end

function ui.getTypes()
    return types
end

function ui.setCurGroup(group)
    UI.curGroup = group
end

function ui.getCurGroup()
    return UI.curGroup
end

ui.addElementType("element", require("ui.element"))
ui.addElementType("panel", require("ui.panel"))
ui.addElementType("button", require("ui.button"))
ui.addElementType("label", require("ui.label"))
ui.addElementType("closeablePanel", require("ui.closeablePanel"))
ui.addElementType("dropdown", require("ui.dropdown"))
ui.addElementType("textbox", require("ui.textbox"))
ui.addElementType("group", require("ui.group"))

return ui
