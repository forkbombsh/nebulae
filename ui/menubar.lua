local panel = require("ui.panel")

local menubar = panel:extend()

function menubar:new(args)
    local b = panel.new(self, args) -- Call the parent constructor

    b.width = args.width or love.graphics.getWidth()
    b.fullSize = b.width == love.graphics.getWidth()
    b.height = args.height or 20
    b.y = 0
    b.x = 0

    return b
end

function menubar:resize(w, h)
    if self.fullSize then
        self.width = w
    end
end

return menubar
