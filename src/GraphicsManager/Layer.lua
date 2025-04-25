Layer = Class("Layer")

function Layer:initialize(obj, project)
    if (type(obj) ~= "table") then
        obj = {}
    end
    local graphicsManager = project.graphicsManager
    self.name = obj.name or "Layer %s"
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
    self.camera = Camera(obj.camera, project)
    if type(obj.fps) ~= "number" then
        self.fps = graphicsManager.fps
    else
        self.fps = obj.fps
    end
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
