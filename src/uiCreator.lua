UIResizer = Class("UIResizer")

function UIResizer:initialize(w, h)
    self.w = w
    self.h = h
    self.ui = {}
end

function UIResizer:add(ref)
    ref.original = { x = ref.x, y = ref.y, w = ref.w, h = ref.h }
    table.insert(self.ui, ref)
end

function UIResizer:resize(w, h)
    for _, ref in ipairs(self.ui) do
        local newWidth = w / self.w
        local newHeight = h / self.h
        ref.x = ref.original.x * newWidth
        ref.y = ref.original.y * newHeight
        ref.w = ref.original.w * newWidth
        ref.h = ref.original.h * newHeight
    end
end
