Object = Class("Object")

function Object:initialize(obj, graphicsManager)
    if (type(obj) ~= "table") then
        obj = {}
    end
    self.x = obj.x or 0
    self.y = obj.y or 0
    self.color = obj.color or { 1, 1, 1, 1 }
    self.startTime = obj.startTime or 0
    self.endTime = obj.endTime or self.startTime + 1
    self.keyframes = obj.keyframes or {}
    self.z = obj.z or 0
    for name, type in pairs(graphicsManager.objectTypes) do
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

function Object:callTypeFunc(name, ...)
    if type(self.type) == "table" and type(self.type[name]) == "function" then
        self.type[name](self, ...)
    end
end

function Object:draw()
    self:callTypeFunc("draw")
end

function Object:update(dt)
    self:callTypeFunc("update", dt)
end
