Container = Class("Container")

function Container:initialize(obj, project)
    if (type(obj) ~= "table") then
        obj = {}
    end
    local graphicsManager = project.graphicsManager
    self.project = project
    self.graphicsManager = graphicsManager
    self.name = TypeCheck(obj.name, "string") and obj.name or "Container"
    if type(obj.msaa) ~= "number" then
        self.msaa = 4
    else
        self.msaa = obj.msaa
    end
    self.canvas = love.graphics.newCanvas(graphicsManager.width, graphicsManager.height, {
        msaa = self.msaa
    })
    self.objects = {}
    self.sortedObjects = {}
    self.pdObjects = obj.objects
    self.camera = Camera(obj.camera, project)
    if type(obj.fps) ~= "number" then
        self.fps = graphicsManager.fps
    else
        self.fps = obj.fps
    end
end

function Container:addObject(object)
    if type(object) == "table" then
        table.insert(self.objects, object)
    end
end

function Container:addObjects()
    if type(self.pdObjects) == "table" then
        for _, pdObject in pairs(self.pdObjects) do
            local object = Object(pdObject, self.project)
            if TypeCheck(object.keyframes, "table") then
                self.project:addKeyframes(object)
            end
            self:addObject(object)
        end
    end
end

function Container:sort()
    for i = 1, #self.objects do
        self.sortedObjects[i] = self.objects[i]
    end
    table.sort(self.sortedObjects, function(a, b)
        return a.zOrder < b.zOrder
    end)
end
