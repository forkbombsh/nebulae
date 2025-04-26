Video = Class("Video")

function Video:initialize(obj, project, video)
    self.volume = obj.volume or 1
    self.looping = obj.looping or false
    self.speed = obj.speed or 1
    self.startTime = obj.startTime or 0
    self.endTime = obj.endTime or obj.startTime + 1
    self.videoTime = obj.videoTime or 0
    self.keyframes = obj.keyframes or {}
    self.project = project
    self.video = video
    local audio = obj.audio
    if type(audio) == "table" then
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
