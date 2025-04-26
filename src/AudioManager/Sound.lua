Sound = Class("Sound")

function Sound:initialize(obj)
    self.volume = obj.volume or 1
    self.looping = obj.looping or false
    self.pitch = obj.pitch or 1
    self.startTime = obj.startTime or 0
    self.endTime = obj.endTime or self.startTime + 1
    self.audioTime = obj.audioTime or 0
    self.keyframes = obj.keyframes or {}
    local soundData = obj.soundData
    if type(soundData.type) == "function" and soundData:type() == "SoundData" then
        self.soundData = soundData
    end
    self.path = obj.file
end
