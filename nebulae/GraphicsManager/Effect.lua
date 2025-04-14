Effect = Class("Effect")

function Effect:initialize(obj, graphicsManager)
    if (type(obj) ~= "table") then
        obj = {}
    end
    self.startTime = obj.startTime or 0
    self.endTime = obj.endTime or self.startTime + 1
    self.keyframes = obj.keyframes or {}
    for name, type in pairs(graphicsManager.effectTypes) do
        if name == obj.type then
            self.type = type
            local mobj = type.init(obj, graphicsManager.project)
            for k, v in pairs(mobj) do
                self[k] = v
            end
            break
        end
    end
end

function Effect:callTypeFunc(name, ...)
    if type(self.type) == "table" and type(self.type[name]) == "function" then
        self.type[name](self, ...)
    end
end