Project = Class("Project")
Project.projects = {}
local socket = require("socket")

local defaultProject = {
    name = "Untitled",
    width = 1280,
    height = 720,
    msaa = 4,
    scale = 1,
    duration = 100,
    creator = "",
    tags = {},
    camera = Camera:getDefault(),
    customTweens = {},
    audio = {}
}

function Project:fetchProjectMeta(name)
    local project = Json.decode(love.filesystem.read("projects/" .. name .. "/metadata.json"))
    return project
end

function Project:fetchProjectLayers(name)
    local project = Json.decode(love.filesystem.read("projects/" .. name .. "/layers.json"))
    return project
end

function Project:getProjectMetaFromDefault(name, width, height)
    local project = table.deepcopy(defaultProject)
    project.name = name
    project.width = width
    project.height = height
    return project
end

function Project:deleteProject(name)
    local path = "projects/" .. name

    RemoveDirectory(path)
end

function Project:createNewProject(project)
    print("Creating new project...")
    for i, v in ipairs(self:getProjectList()) do
        if v.name == project.name then
            local num = tonumber(project.name:sub(-1))
            if num then
                project.name:sub(1, #project.name - 1)
                local base = project.name:match("^(.-)%s*#?%d*$") or project.name
                project.name = base .. " #" .. tostring(num and num + 1 or 1)
            else
                project.name = project.name .. " #1"
            end
        end
    end
    local folderDir = SanitizeFilename(project.name, 255)
    NativeFS.createDirectory("projects/" .. folderDir)
    NativeFS.write("projects/" .. folderDir .. "/metadata.json", Json.encode(project))
    NativeFS.write("projects/" .. folderDir .. "/layers.json", "[]")
    return folderDir
end

function Project:initialize(name)
    self.name = self:fetchProjectMeta(name).name
    self.folder = "projects/" .. name
    self.folderName = name
    self.isLoaded = false
    Project.projects[name] = self
end

function Project:addKeyframes(obj)
    for _, keyframe in ipairs(obj.keyframes) do
        local tween = Tween(obj, keyframe.values, keyframe.startTime, keyframe.endTime,
            KeyframeManager.curves[keyframe.type] or keyframe.curve or KeyframeManager.curves.linear)
        self.keyframeManager:addTween(tween)
    end
end

function Project:load(onFinish)
    print("Loading project...")

    local oldtime = socket.gettime()

    local folderName = self.folderName

    self.player = Player()
    self.keyframeManager = KeyframeManager()

    local player = self.player
    local folder = self.folder

    print("Loading JSON...")

    local projectMeta = self:fetchProjectMeta(folderName)
    player:reset()

    player.duration = projectMeta.duration

    self.audioManager = AudioManager(self)
    local audioManager = self.audioManager

    self.videoManager = VideoManager(self)
    local videoManager = self.videoManager

    local msaa = projectMeta.msaa

    if not TypeCheck(msaa, "number") then
        msaa = 4
    end

    self.graphicsManager = GraphicsManager(projectMeta.width, projectMeta.height, projectMeta.framerate, msaa, self)
    local graphicsManager = self.graphicsManager

    print("loading plugins...")
    self.pluginManager = ProjectPluginManager(self, Nebulae.pluginsDir)

    self.pluginManager:loadAllPlugins()
    self.isLoaded = true

    print("Loading objects and layers...")

    local pdLayers = self:fetchProjectLayers(folderName)

    for layerIndex, pdLayer in ipairs(pdLayers) do
        local layer = Layer(pdLayers[layerIndex], self)
        local deepCopiedObjects = table.deepcopy(pdLayer.objects)
        for _, pdObject in pairs(deepCopiedObjects) do
            local object = Object(pdObject, graphicsManager)
            if TypeCheck(object.keyframes, "table") then
                self:addKeyframes(object)
            end
            layer:addObject(object)
        end
        print("Sorting layer...")
        layer:sort()
        graphicsManager:addLayer(layer)
    end

    print("Loading audio...")

    local soundDatas = {}

    for _, audio in ipairs(projectMeta.audio) do
        local audioPath = folder .. "/" .. audio.file
        local soundData = audioManager:loadSoundData(audioPath)
        audio.soundData = soundData
        local sound = Sound(audio)
        table.insert(soundDatas, sound)
        audioManager:addRTSound(sound)
    end

    audioManager:loadingFinished()

    if TypeCheck(onFinish, "function") then
        onFinish()
    end

    local newtime = socket.gettime()
    print("Project loaded in " .. (newtime - oldtime) .. " seconds.")
end

function Project:checkForErrors()
    pprint(self.audioManager:checkForErrors())
end

function Project:unload()
    self.isLoaded = false
    local oldtime = socket.gettime()
    print("Unloading project...")
    self.graphicsManager:unload()
    self.audioManager:unload()
    self.pluginManager:unload()
    self.videoManager:unload()
    self.graphicsManager = nil
    self.audioManager = nil
    self.pluginManager = nil
    self.player = nil
    self.keyframeManager = nil
    self.videoManager = nil
    Project.projects[self.name] = nil
    collectgarbage("collect")
    local newtime = socket.gettime()
    print("Project unloaded in " .. (newtime - oldtime) .. " seconds.")
end

function Project:update(dt)
    if not self.isLoaded then return end
    self.player:update(dt)
    self.keyframeManager:update(self.player.time)
    self.graphicsManager:update(dt)
    self.videoManager:update()
    self.audioManager:update()
end

function Project:updateAll(dt)
    for _, project in pairs(Project.projects) do
        project:update(dt)
    end
end

function Project:getProjectList()
    local list = {}

    for i, v in ipairs(love.filesystem.getDirectoryItems("projects")) do
        if love.filesystem.getInfo("projects/" .. v).type == 'directory' then
            if love.filesystem.getInfo("projects/" .. v .. "/metadata.json") then
                table.insert(list, v)
            end
        end
    end

    return list
end
