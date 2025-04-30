Video = Class("Video")
local cache = {}

function Video:initialize(obj, project)
    self.volume = TypeCheck(obj.volume, "number") and obj.volume or 1
    self.looping = TypeCheck(obj.looping, "boolean") and obj.looping or false
    self.speed = TypeCheck(obj.speed, "number") and obj.speed or 1
    self.startTime = TypeCheck(obj.startTime, "number") and obj.startTime or 0
    self.endTime = TypeCheck(obj.endTime, "number") and obj.endTime or self.startTime + 1
    self.videoTime = TypeCheck(obj.videoTime, "number") and obj.videoTime or 0
    self.keyframes = TypeCheck(obj.keyframes, "table") and obj.keyframes or {}
    self.project = project
    local tempPath = TempPath
    local filename = obj.video
    local baseName = filename:match("(.+)%..+")
    local videoOnlyAudio = baseName .. "-aud.wav"
    local videoNoAudio = baseName .. "-vid.mp4"
    local audioPathFull = tempPath .. "/" .. videoOnlyAudio
    local videoPathFull = tempPath .. "/" .. videoNoAudio
    if not NativeFS.getInfo(audioPathFull) or not NativeFS.getInfo(videoPathFull) then
        os.execute(("ffmpeg -i \"%s\" -vn -acodec pcm_s16le -ar 48000 -ac 2 \"%s\" -an -vcodec copy \"%s\" -y")
            :format(project.folder .. "/" .. filename, audioPathFull, videoPathFull))
    end
    if not NativeFS.getInfo(audioPathFull) or not NativeFS.getInfo(videoPathFull) then
        return
    end
    local audioPathFile = love.filesystem.openNativeFile(audioPathFull, "r")
    local videoPathFile = love.filesystem.openNativeFile(videoPathFull, "r")
    local video = love.graphics.newVideo(videoPathFile)
    local source = video:getSource()
    if source then
        source:setVolume(0)
    end
    if TypeCheck(audioPathFile, "string") and TypeCheck(videoOnlyAudio, "string") then
        if not love.filesystem.getInfo(audioPathFile) or not love.filesystem.getInfo(videoOnlyAudio) then
            return
        end
        print(audioPathFile)
        local soundData = project.audioManager:loadSoundData(audioPathFile)
        local sound = Sound({
            soundData = soundData,
            startTime = self.startTime,
            endTime = self.endTime,
            audioTime = self.videoTime
        })
        sound.path = videoOnlyAudio
        project.audioManager:addRTSound(sound)
        audio = sound
    end
    local audio = obj.audio
    if TypeCheck(audio, "table") then
        self.audio = audio
    end
end

function Video:update()
    if not self.video then return end
    local time = self.project.player.time
    local videoTime = math.min(math.max(time - self.startTime + self.videoTime, 0), self.endTime)
    self.video:seek(videoTime)
end

function Video:unload()
    self.video:release()
end
