Camera = Class("Camera")

local defaultCamera = {
    x = 0,
    y = 0,
    zoom = 1,
    rotation = 0,
    ox = 0.5,
    oy = 0.5,
    stretchX = 1,
    stretchY = 1,
    layerParallaxEffect = false,
    keyframes = {}
}

function Camera:getDefault()
    return table.deepcopy(defaultCamera)
end

function Camera:initialize(obj, project)
    if (type(obj) ~= "table") then
        obj = {}
    end
    self.x = obj.x or 0
    self.y = obj.y or 0
    self.zoom = obj.zoom or 1
    self.rotation = obj.rotation or 0
    self.originX = obj.ox or 0.5
    self.originY = obj.oy or 0.5
    self.stretchX = obj.stretchX or 1
    self.stretchY = obj.stretchY or 1
    self.layerParallaxEffect = obj.layerParallaxEffect or false
    self.keyframes = obj.keyframes or {}
    self.graphicsManager = project.graphicsManager
    if type(self.keyframes) == "table" then
        project:addKeyframes(self)
    end
end

function Camera:push()
    local graphicsManager = self.graphicsManager
    love.graphics.push()
    if graphicsManager then
        local ox, oy = (self.originX or 0.5) * graphicsManager.width, (self.originY or 0.5) * graphicsManager.height
        love.graphics.translate(ox, oy)
        love.graphics.scale(self.zoom or 1)
        love.graphics.scale(self.stretchX or 1, self.stretchY or 1)
        love.graphics.rotate(math.rad(self.rotation or 0))
        love.graphics.translate(-ox, -oy)
        love.graphics.translate(-self.x, -self.y)
    end
end

function Camera:pop()
    love.graphics.pop()
end
