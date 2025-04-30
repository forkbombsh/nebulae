Container = Class("Container")

function Container:initialize(obj, project)
    if (type(obj) ~= "table") then
        obj = {}
    end
    local graphicsManager = project.graphicsManager
    self.project = project
    self.graphicsManager = graphicsManager
    self.player = self.project.player
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
    self.pdObjects = table.deepcopy(obj.objects)
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
            -- StartProfile("create object")
            local object = Object(pdObject, self.project)
            if TypeCheck(object.keyframes, "table") then
                self.project:addKeyframes(object)
            end
            self:addObject(object)
            -- EndProfile("create object")
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

function Container:drawToCanvas()
    local player = self.player
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)
    for _, object in ipairs(self.sortedObjects) do
        if type(object) == "table" and type(object.type) == "table" and type(object.type.draw) == "function" then
            if player.time >= object.startTime and player.time < object.endTime then
                local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(1, 1, 1, 1)
                object:draw()
                love.graphics.setColor(r, g, b, a)
            end
        end
    end
    love.graphics.setCanvas()
end

function Container:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0)
end