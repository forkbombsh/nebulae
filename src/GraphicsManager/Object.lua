Object = Class("Object")

function Object:initialize(obj, project)
    if (type(obj) ~= "table") then
        obj = {}
    end
    local graphicsManager = project.graphicsManager
    self.x = TypeCheck(obj.x, "number") and obj.x or 0
    self.y = TypeCheck(obj.y, "number") and obj.y or 0
    self.z = TypeCheck(obj.y, "number") and obj.z or 0
    self.color = TypeCheck(obj.color, "table") and obj.color or { 1, 1, 1, 1 }
    self.startTime = TypeCheck(obj.startTime, "number") and obj.startTime or 0
    self.endTime = TypeCheck(obj.endTime, "number") and obj.endTime or self.startTime + 1
    self.keyframes = TypeCheck(obj.keyframes, "table") and obj.keyframes or {}
    self.zOrder = TypeCheck(obj.zOrder, "number") and obj.zOrder or 0
    for name, type in pairs(graphicsManager.objectTypes) do
        if name == obj.type then
            self.type = type
            local mobj = type.init(obj, project)
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
