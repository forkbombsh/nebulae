Layer = Class("Layer")

function Layer:initialize(obj, graphicsManager)
    if (type(obj) ~= "table") then
        obj = {}
    end
    self.graphicsManager = graphicsManager
    self.name = obj.name or "Layer %s"
    self.canvas = love.graphics.newCanvas(graphicsManager.width, graphicsManager.height)
    self.objects = {}
    self.sortedObjects = {}
    self.camera = Camera(obj.camera, graphicsManager)
end

function Layer:addObject(object)
    if type(object) == "table" then
        table.insert(self.objects, object)
    end
end

function Layer:sort()
    for i = 1, #self.objects do
        self.sortedObjects[i] = self.objects[i]
    end
    table.sort(self.sortedObjects, function(a, b)
        return a.z < b.z
    end)
end