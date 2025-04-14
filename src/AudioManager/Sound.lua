Sound = Class("Sound")

function Sound:initialize(obj)
    obj.volume = obj.volume or 1
    obj.looping = obj.looping or false
    obj.pitch = obj.pitch or 1
    obj.startTime = obj.startTime or 0
    obj.endTime = obj.endTime or obj.startTime + 1
    obj.audioTime = obj.audioTime or 0
    obj.keyframes = obj.keyframes or {}
    local soundData = obj.soundData
    if type(soundData.type) == "function" and soundData:type() == "SoundData" then
        obj.soundData = soundData
    end
    obj.path = obj.file
    return obj
end
