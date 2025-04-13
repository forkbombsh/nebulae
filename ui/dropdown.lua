local closeablePanel = require("ui.closeablePanel")

local dropdown = closeablePanel:extend()

function dropdown:new(args)
    local b = closeablePanel.new(self, args) -- Call the parent constructor

    -- Set default width and height
    b.width = args.width or 200
    b.height = args.height or 200

    -- Set exclusions, defaulting to an empty table
    b.exclusions = args.exclusions or {}

    return b
end

-- Improved exclusions check
function dropdown:isInExclusions(x, y)
    for _, v in ipairs(self.exclusions) do
        if x >= v.x and x <= v.x + v.width and y >= v.y and y <= v.y + v.height then
            return true
        end
    end
    return false
end

-- Mouse pressed handling, with early return
function dropdown:mousepressed(x, y)
    if not self:isMouseInside() and not self:isInExclusions(x, y) then
        self:close()
    end
end

return dropdown
