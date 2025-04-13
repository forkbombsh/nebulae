local json = require("lib.json")
local Player = require("src.Player")
local timeTween = require("src.timeTween")
local graphicsManager = require("src.graphicsManager")
local audioManager = require("src.audioManager")
local group = timeTween.newGroup()

local Loader = Class("Loader")

local types = {
    audio = audioManager,
    graphic = graphicsManager
}

function Loader:newCamera(obj)
    obj.x = obj.x or 0
    obj.y = obj.y or 0
    obj.sx = obj.sx or 1
    obj.sy = obj.sy or 1
    obj.rotation = obj.rotation or 0
    obj.zoom = obj.zoom or 1
    obj.layerParallaxEffect = obj.layerParallaxEffect or false
    obj.ox = obj.ox or 0.5
    obj.oy = obj.oy or 0.5
    obj.keyframes = obj.keyframes or {}
    return obj
end

function Loader:newLayer(obj)
    obj.name = obj.name or "Layer %s"
    obj.objects = obj.objects or {}
    obj.hasCamera = obj.hasCamera or false
    obj.camera = obj.camera or {}
    obj.parallaxSpeed = obj.parallaxSpeed or 0
    obj.blendMode = obj.blendMode or "normal"
    obj.depth = obj.depth or false
    return obj
end

function Loader:addKeyframes(obj)
    if obj.keyframes then
        for _, keyframe in ipairs(obj.keyframes) do
            local targetKeyframe = {}
            for key, value in pairs(keyframe) do
                if key ~= "endTime" and key ~= "startTime" then
                    targetKeyframe[key] = value
                end
            end
            group:newTween(keyframe.startTime or keyframe.time or 0, keyframe.endTime or 0,
                ((timeTween.curves[keyframe.type] or keyframe.curve) or timeTween.curves.linear),
                obj, targetKeyframe)
        end
    end
end

function Loader:loadProject(name)
    Player.time = 0
    Player.speed = 1
    Player.isPlaying = false
    Player.isLooping = false
    Player.events = {}
    group:kill()
    local folder = "projects/" .. name
    local projectData = json.decode(love.filesystem.read(folder .. "/project.json"))
    Player.name = name
    Player.projectData = projectData
    local endTime = projectData.endTime

    audioManager.onStart(name)
    graphicsManager.onStart(name)

    graphicsManager.newCanvas(projectData.width, projectData.height)
    graphicsManager.fps = projectData.framerate

    if type(projectData.camera) ~= "table" then
        projectData.camera = {}
    end

    for layerIndex, _ in ipairs(projectData.layers) do
        local layer = self:newLayer(projectData.layers[layerIndex])
        if type(layer.camera) == "table" then
            print(("Layer named `%s` has a camera"):format(layer.name))
            layer.camera = self:newCamera(layer.camera)
            self:addKeyframes(layer.camera)
            layer.hasCamera = true
        elseif layer.camera ~= nil and type(layer.camera) ~= "table" then
            layer.camera = nil
            layer.hasCamera = false
        end
        graphicsManager.addLayer(layer)
        for _, object in ipairs(layer.objects) do
            if object.type == "graphic" then
                object.layer = layerIndex
                self:addKeyframes(object)
                graphicsManager.add(object)
            end
        end
    end

    for _, audio in ipairs(projectData.audio) do
        audioManager.add(audio)
    end

    local camera = self:newCamera(projectData.camera)

    graphicsManager.camera = camera
    self:addKeyframes(camera)

    Player.group = group
    Player.endTime = endTime

    audioManager.onFinish()
end

function Loader:unload()
    for _, v in ipairs(types) do
        if v.unload then
            v.unload()
        end
    end
    Player:stop()
    Player.endTime = 0
    Player.isReversed = false
end

return Loader
