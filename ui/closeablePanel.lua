local panel = require("ui.panel")
local shared = require("ui.shared")
local ui = shared.ui

local closeablePanel = panel:extend()

function closeablePanel:new(args)
    local b = panel.new(self, args) -- Call the parent constructor

    b.isOpen = false

    b.onOpened = args.onOpened or function(_, _) end
    b.onClosed = args.onClosed or function(_, _) end

    return b
end

function closeablePanel:close()
    ui.remove(self)
    self:onClosed()
end

function closeablePanel:open()
    ui.add(self)
    self:onOpened()
end

function closeablePanel:toggle()
    if self.isOpen then
        self:close()
    else
        self:open()
    end
end

return closeablePanel
