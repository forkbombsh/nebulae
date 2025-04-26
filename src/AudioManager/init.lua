require("src.AudioManager.Sound")
AudioManager = Class("AudioManager")

function AudioManager:initialize(project)
    print("init audio manager")
    self.soundDatas = {}
    self.sounds = {}
    self.sources = {}
    self.project = project
    self.player = self.project.player
    self.lastPlayedAudioID = 0
    self.lastFinishedAudioID = 0
    self.averageSample = 0
end

function AudioManager:addRTSound(sound)
    if sound.soundData then
        if self.sources[sound.path] then
            sound.source = self.sources[sound.path]:clone()
        else
            sound.source = love.audio.newSource(sound.soundData)
            self.sources[sound.path] = sound.source
            if sound.looping then
                sound.source:setLooping(true)
            end
        end
        sound.source:setVolume(sound.volume)
        sound.source:setPitch(sound.pitch)
        sound.source:seek(sound.audioTime)
    end
    table.insert(self.sounds, sound)
end

function AudioManager:loadingFinished()
    print("Sorting audio...")
    table.sort(self.sounds, function(a, b) return a.startTime < b.startTime end)
end

function AudioManager:loadSoundData(path)
    if self.soundDatas[path] == nil then
        self.soundDatas[path] = love.sound.newSoundData(path)
        table.insert(self.soundDatas, self.soundDatas[path])
    end
    return self.soundDatas[path]
end

function AudioManager:resampleSoundData(soundData, targetRate)
    local currentRate = soundData:getSampleRate()
    if currentRate == targetRate then return soundData end

    local numChannels = soundData:getChannelCount()
    local sampleCount = soundData:getSampleCount()
    local newSampleCount = math.floor(sampleCount * (targetRate / currentRate))
    local newSoundData = love.sound.newSoundData(newSampleCount, targetRate, 16, numChannels)

    for i = 0, newSampleCount - 1 do
        local originalIndex = i * (currentRate / targetRate)
        local indexA = math.floor(originalIndex)
        local indexB = math.min(indexA + 1, sampleCount - 1)
        local t = originalIndex - indexA

        for c = 1, numChannels do
            local sampleA = soundData:getSample(indexA, c)
            local sampleB = soundData:getSample(indexB, c)
            local interpolatedSample = sampleA + (sampleB - sampleA) * t
            newSoundData:setSample(i, c, interpolatedSample)
        end
    end

    return newSoundData
end

function AudioManager:getint32(value)
    return string.char(bit.band(value, 0xFF), bit.band(bit.rshift(value, 8), 0xFF), bit.band(bit.rshift(value, 16), 0xFF),
        bit.band(bit.rshift(value, 24), 0xFF))
end

function AudioManager:getint16(value)
    return string.char(bit.band(value, 0xFF), bit.band(bit.rshift(value, 8), 0xFF))
end

function AudioManager:convert16to8(sample16)
    return math.floor((sample16 + 32768) / 256)
end

function AudioManager:convert8to16(sample8)
    return (sample8 * 256) - 32768
end

function AudioManager:encodeWAV(samples, sampleRate, channels, bitsPerSample)
    local numSamples = #samples
    local byteRate = sampleRate * channels * (bitsPerSample / 8)
    local blockAlign = channels * (bitsPerSample / 8)

    local out = {}

    local function write(value)
        table.insert(out, value)
    end

    -- write header
    write("RIFF")
    write(AudioManager:getint32(36 + numSamples * channels * (bitsPerSample / 8)))
    write("WAVE")

    -- write fmt chunk
    write("fmt ")
    write(AudioManager:getint32(16)) -- fmt chunk size
    write(AudioManager:getint16(1))  -- audio format (1 = pcm)
    write(AudioManager:getint16(channels))
    write(AudioManager:getint32(sampleRate))
    write(AudioManager:getint32(byteRate))
    write(AudioManager:getint16(blockAlign))
    write(AudioManager:getint16(bitsPerSample))

    -- write data chunk
    write("data")
    write(AudioManager:getint32(numSamples * channels * (bitsPerSample / 8)))

    -- write samples
    for i = 1, numSamples do
        for c = 1, channels do
            local sample = samples[i][c]

            if bitsPerSample == 8 then
                sample = math.floor((sample + 1) * 127)
                write(string.char(sample))
            elseif bitsPerSample == 16 then
                sample = math.floor(sample * 32767)
                write(string.char(bit.band(sample, 0xFF), bit.band(bit.rshift(sample, 8), 0xFF)))
            end
        end

        samples[i] = nil
    end

    samples = nil

    collectgarbage("collect")

    return table.concat(out, "")
end

function AudioManager:encodeSoundDataWav(soundData)
    local channels = soundData:getChannelCount()
    local sampleRate = soundData:getSampleRate()
    local bitsPerSample = soundData:getBitDepth()
    local samples = {}

    for i = 0, soundData:getSampleCount() - 1 do
        local sample = {}
        for c = 1, channels do
            sample[c] = soundData:getSample(i, c)
        end
        table.insert(samples, sample)
    end

    return AudioManager:encodeWAV(samples, sampleRate, channels, bitsPerSample)
end

function AudioManager:combineSoundDatas(soundDatas, maxEndTime)
    if #soundDatas == 0 then return nil end

    for i, v in ipairs(soundDatas) do
        soundDatas[i].soundData = AudioManager:resampleSoundData(v.soundData, 48000 / (v.pitch or 1.0))
    end

    local earliestStart = math.huge
    local latestEnd = -math.huge
    local sampleRate = 48000
    local numChannels = soundDatas[1].soundData:getChannelCount()

    -- Use startTime/endTime for determining total combined length
    for _, v in ipairs(soundDatas) do
        earliestStart = math.min(earliestStart, v.startTime)
        latestEnd = math.max(latestEnd, v.endTime)
    end

    local totalDuration = latestEnd - earliestStart
    local numSamples = math.ceil(totalDuration * sampleRate)
    if numSamples < 1 then return end
    local combinedSound = love.sound.newSoundData(numSamples, sampleRate, 16, numChannels)

    local currentTime = 0

    for _, v in ipairs(soundDatas) do
        local soundData = v.soundData
        local volume = v.volume or 1.0
        local looping = v.looping or false

        local startSample = math.floor((v.startTime - earliestStart) * sampleRate)
        local endSample = math.floor((v.endTime - earliestStart) * sampleRate)

        -- Start reading from this offset inside the source sound
        local sourceStartOffset = math.floor((v.audioTime or 0) * sampleRate)
        local sampleCount = soundData:getSampleCount()

        local sampleIndex = startSample
        while sampleIndex < endSample do
            for i = 0, sampleCount - 1 do
                if sampleIndex >= endSample then break end

                -- Actual sample index inside source sound
                local sourceIndex = sourceStartOffset + i
                if not looping and sourceIndex >= sampleCount then
                    break
                end
                local loopSample = sourceIndex % sampleCount

                for ch = 1, numChannels do
                    local sampleValue = soundData:getSample(loopSample, ch) * volume
                    local existingValue = combinedSound:getSample(sampleIndex, ch) or 0
                    local finalValue = math.max(-1, math.min(existingValue + sampleValue, 1))
                    combinedSound:setSample(sampleIndex, ch, finalValue)
                end

                sampleIndex = sampleIndex + 1
                currentTime = sampleIndex / sampleRate

                -- Check if maxEndTime is specified and reached
                if maxEndTime and currentTime >= maxEndTime then
                    return combinedSound
                end
            end
            if not looping then break end
        end
    end

    return combinedSound
end

function AudioManager:update()
    local player = self.player
    local time = player.time
    local isPlaying = player.isPlaying

    self.averageSample = 0
    local curPlayingCount = 0

    -- get average sample of all currently playing sounds
    for i = 1, #self.sounds do
        local sound = self.sounds[i]

        sound.shouldPlay = time >= sound.startTime and time < sound.endTime

        if sound.shouldPlay then
            local channelCount = sound.soundData:getChannelCount()
            local sample = sound.soundData:getSample(sound.source:tell("samples"))
            curPlayingCount = curPlayingCount + 1
            self.averageSample = self.averageSample + sample
        end
    end

    self.averageSample = self.averageSample / curPlayingCount

    if Renderer.isRendering then
        return
    end

    for i = 1, #self.sounds do
        local sound = self.sounds[i]

        if time < sound.startTime then
            if sound.source:isPlaying() then
                sound.source:pause()
            end
            break
        end

        if time >= sound.startTime and time < sound.endTime then
            local pitch = sound.pitch or 1
            if pitch == 0 then pitch = 0.0001 end

            local expectedPos = (time - sound.startTime) * pitch + sound.audioTime

            if isPlaying then
                if not sound.source:isPlaying() then
                    sound.source:seek(expectedPos)
                    sound.source:play()
                else
                    local actualPos = sound.source:tell()
                    local tolerance = 0.1 / pitch -- more forgiving when pitch is lower
                    if math.abs(actualPos - expectedPos) > tolerance then
                        sound.source:seek(expectedPos)
                    end
                end
            else
                if sound.source:isPlaying() then
                    sound.source:pause()
                end

                -- Only seek when not playing if position is *different* enough
                local actualPos = sound.source:tell()
                if math.abs(actualPos - expectedPos) > 0.01 then
                    sound.source:seek(expectedPos)
                end
            end
        elseif sound.source:isPlaying() then
            sound.source:pause()
        end
    end
end

function AudioManager:unload()
    for _, sound in pairs(self.sounds) do
        sound.source:stop()
        sound.source:release()
        sound.soundData:release()
    end
    for i, v in ipairs(self.sources) do
        v:stop()
        v:release()
    end
end

function AudioManager:checkForErrors()
    local ids = {}
    local out = {}
    for _, sound in pairs(self.sounds) do
        local soundID = ids[sound.id]
        if sound.id and soundID then
            table.insert(out,
                ("Duplicate sound id '%s' with file '%s' (previous file '%s')"):format(sound.id, sound.file, soundID
                    .file))
        elseif sound.id then
            ids[sound.id] = sound
        end
    end

    return out
end
