require("src.GraphicsManager.Object")
require("src.GraphicsManager.Container")
require("src.GraphicsManager.Camera")
require("src.GraphicsManager.Effect")
GraphicsManager = Class("GraphicsManager")

function GraphicsManager:initialize(width, height, fps, msaa, project)
    print("init graphics manager")
    width = width or 1280
    height = height or 720
    fps = fps or 60
    self.canvas = love.graphics.newCanvas(width, height, {
        msaa = msaa
    })
    self.camera = Camera(project.camera, project)
    self.project = project
    self.player = project.player
    self.fps = fps
    self.width = width
    self.height = height
    self.layers = {}
    self.objectTypes = {}
    self.effectTypes = {}
    self.backgroundColor = { 0, 0, 0 }
end

function GraphicsManager:addLayer(layer)
    if type(layer) ~= "table" then
        layer = {}
    end
    table.insert(self.layers, layer)
end

function GraphicsManager:registerObjectType(args)
    if type(args) == "table" then
        local name = args.name or "object"
        self.objectTypes[name] = args
    end
end

function GraphicsManager:registerEffectType(args)
    if type(args) == "table" then
        local name = args.name or "effect"
        self.effectTypes[name] = args
    end
end

function GraphicsManager:drawLayer(layer)
    local player = self.player
    love.graphics.setColor(1, 1, 1, 1)
    for _, object in ipairs(layer.sortedObjects) do
        if type(object) == "table" and type(object.type) == "table" and type(object.type.draw) == "function" then
            if player.time >= object.startTime and player.time < object.endTime then
                local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(1, 1, 1, 1)
                object:draw()
                love.graphics.setColor(r, g, b, a)
            end
        end
    end
end

function GraphicsManager:updateLayer(layer, dt)
    for _, object in ipairs(layer.sortedObjects) do
        object:update(dt)
    end
end

function GraphicsManager:drawLayers()
    for _, layer in ipairs(self.layers) do
        layer.camera:push()
        self:drawLayer(layer)
        layer.camera:pop()
    end
end

function GraphicsManager:canvasifyObject(object)
    local canvas = love.graphics.newCanvas(object.width, object.height)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)
    object:draw()
    love.graphics.setCanvas()
    return canvas
end

function GraphicsManager:draw()
    self.camera:push()
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0)
    love.graphics.setColor(r, g, b, a)
    self.camera:pop()
end

function GraphicsManager:unload()
    for _, layer in ipairs(self.layers) do
        layer.canvas:release()
        for _, object in ipairs(layer.objects) do
            object:callTypeFunc("unload")
        end
    end
    self.canvas:release()
    self.objectTypes = nil
    self.canvas = nil
    self.layers = nil
end

function GraphicsManager:update(dt)
    for _, layer in ipairs(self.layers) do
        self:updateLayer(layer, dt)
    end
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    self:drawLayers()
    love.graphics.setCanvas()
end
