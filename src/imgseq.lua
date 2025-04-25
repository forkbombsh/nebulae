local imgseq = {}
local json = require("lib.json")
local seqs = {}
local imgChan = love.thread.getChannel("img")
local timer = 0
local cached = {}

local function newSeqThread()
    local thread = love.thread.newThread [[
        require("love.image")
        local id, toLoad, chunkSize = ...
        chunkSize = tonumber(chunkSize)
        local chunks=0
        if chunkSize>#toLoad then
            chunkSize=#toLoad
        end
        local imgChan = love.thread.getChannel("img")
        local imgs={}
        for i, v in ipairs(toLoad) do
            local img = love.image.newImageData(v)
            print(i)
            imgs[#imgs+1]=img
            if #imgs>=chunkSize then
        chunks=chunks+1
        print("a")
                imgChan:push({id, imgs,chunks})
                imgs={}
            end
        end
    ]]
    return thread
end

local seqIndex = 0

local function wrap(file, config, toLoad, releaseold, canvas, seq)
    local wrapped = {
        file = file,
        config = config,
        imgs = {},
        current = 1,
        currentOld = 0,
        timeCreated = timer,
        toLoad = toLoad,
        id = seqIndex,
        loop = true,
        releaseold = releaseold,
        audioSyncTimer = 4,
        canvas = canvas,
        chunkSize = 20,
        reverse = false,
        isPlaying = false,
        max = 0,
        min = 0,
        speed = 1,
        play = function(self)
            self.isPlaying = true
        end,
        playOnce = function(self)
            self.isPlaying = true
            self.loop = false
        end,
        pause = function(self)
            self.isPlaying = false
        end,
        stop = function(self)
            self.isPlaying = false
            self.current = 1
        end,
        toggle = function(self)
            self.isPlaying = not self.isPlaying
        end,
        setSpeed = function(self, speed)
            self.speed = speed
        end,
        setFPS = function(self, fps)
            self.config.fps = fps
            self.config.speed = 1 / fps
        end,
        setLoop = function(self, loop)
            self.loop = loop
        end,
        setReverse = function(self, reverse)
            self.reverse = reverse
        end,
        setChunkSize = function(self, chunkSize)
            self.chunkSize = chunkSize
        end,
        getFPS = function(self)
            return self.config.fps
        end,
        getSpeed = function(self)
            return self.config.speed
        end,
        getLoop = function(self)
            return self.loop
        end,
        getReverse = function(self)
            return self.reverse
        end,
        getChunkSize = function(self)
            return self.chunkSize
        end,
        setFrame = function(self, frame)
            self.current = frame
        end,
        getFrame = function(self)
            return self.current
        end,
        getFrameAmount = function(self)
            return #self.imgs
        end,
        getFrames = function(self)
            return self.imgs
        end,
        setFrameRange = function(self, start, stop)
            self.min = start
            self.max = stop
            print(self.min, self.max, start, stop)
        end,
        getFrameRange = function(self)
            return self.min, self.max
        end,
        clone = function(self)
            return wrap(file, config, toLoad, releaseold, canvas, seq)
        end
    }
    return wrapped
end

function imgseq.load(file, releaseold)
    local configPath = ("%s@config.json"):format(file)
    local configData = love.filesystem.read(configPath)
    local config = json.decode(configData)
    local canvas = love.graphics.newCanvas(config.width, config.height)
    config.speed = 1 / config.fps
    local toLoad = {}
    local index = 0
    while true do
        index = index + 1
        local path = ("%s@%d.%s"):format(file, index, config.ext)
        if not love.filesystem.getInfo(path) then
            break
        end
        local img = path
        toLoad[index] = img
    end
    seqIndex = seqIndex + 1
    if cached[file] then
        return wrap(file, config, toLoad, releaseold, canvas, cached[file])
    end

    local seq = wrap(file, config, toLoad, releaseold, canvas)

    seq.max = #toLoad
    seq.min = 0

    local thread = newSeqThread()
    thread:start(seq.id, seq.toLoad, seq.chunkSize)
    seqs[seqIndex] = seq

    cached[file] = seq

    return seq
end

function imgseq.update(dt)
    timer = timer + dt
    local img = imgChan:pop()
    if img then
        local seq = seqs[img[1]]
        if seq then
            local curX = 0
            local curY = 0
            local a = {}
            for i, v in ipairs(img[2]) do
                v = love.graphics.newImage(v)
                table.insert(seq.imgs, v)
                table.insert(a, v)
            end
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            for i, v in ipairs(a) do
                love.graphics.draw(v, curX, curY)
                curX = curX + v:getWidth()
                if curX + v:getWidth() >= love.graphics.getWidth() then
                    curX = 0
                    curY = v:getHeight()
                end
            end
            love.graphics.present()
            love.timer.sleep(1/50)
        end
    end
    for i, v in ipairs(seqs) do
        if v.isPlaying then
            v.audioSyncTimer = v.audioSyncTimer + dt
            if v.currentOld ~= v.current and #v.toLoad == #v.imgs then
                love.graphics.setCanvas(v.canvas)
                love.graphics.clear()
                local img = v.imgs[v.current]
                if img then
                    love.graphics.draw(img, 0, 0)
                end
                love.graphics.setCanvas()
                v.currentOld = v.current
            end
            local frameAdvance
            if not v.loop then
                frameAdvance = v.min + math.floor((timer * v.config.fps) * v.speed)
                frameAdvance = math.min(frameAdvance, v.max)
                if v.releaseold then
                    for j = 1, frameAdvance - 1 do
                        if v.imgs[j] then
                            v.imgs[j]:release()
                        end
                    end
                end
            else
                frameAdvance = v.min + math.floor((((timer * v.config.fps) * v.speed) - v.timeCreated) % (v.max - v.min))
            end
            if v.reverse then
                v.current = v.max - frameAdvance
            else
                v.current = frameAdvance
            end
            if v.audio then
                if v.audioSyncTimer >= 1 then
                    v.audioSyncTimer = 0
                    local timePerFrame = 1 / v.config.fps
                    local seekTime = (v.current - 1) * timePerFrame
                    seekTime = math.max(seekTime, 0)
                    v.audio:seek(seekTime)
                end
            end
        end
    end
end

function imgseq.getLoadedPercent(seq)
    return math.floor((#seq.imgs / #seq.toLoad) * 100)
end

function imgseq.getPlayedPercent(seq)
    return math.floor((seq.current / #seq.toLoad) * 100)
end

return imgseq
