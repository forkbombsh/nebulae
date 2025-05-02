local state = {}

local width = 1280/2
local height = 720/2
local frame_size = width * height * 4
local audio = love.audio.newSource("a/nullscape.mp4", "stream")
local fps = 60
local lastCurFrame = 0
local time = 0

function state:enter()
    love.window.setFullscreen(true)
    self.preloadTarget = 240 -- number of frames to preload
    self.frameCoroutine = coroutine.create(function()
        while true do
            local frame = self.pipe:read(frame_size)
            if not frame or #frame < frame_size then return end

            local tex = love.image.newImageData(width, height, "rgba8", frame)
            local img = love.graphics.newImage(tex)
            img:replacePixels(tex)
            table.insert(self.frames, img)

            coroutine.yield() -- yield after each frame
        end
    end)
    local cmd = string.format(
        'ffmpeg -hwaccel cuda -i a/nullscape.mp4 -f rawvideo -pix_fmt rgba -s %dx%d -vcodec rawvideo -an -nostdin -loglevel debug -',
        width, height, fps
    )
    self.pipe = io.popen(cmd, "rb")
    self.frameTime = 1 / 60
    self.accumulator = 0
    self.frames = {}
    self.canvas = love.graphics.newCanvas(width, height)
    self.texture = love.graphics.newImage(love.image.newImageData(width, height))
    audio:play()
end

function state:update(dt)
    time = time + dt -- sync to actual audio time
    local toPreload = self.preloadTarget - fps

    local maxPerUpdate = 3
    for i = 1, math.min(toPreload, maxPerUpdate) do
        if coroutine.status(self.frameCoroutine) == "dead" then break end
        coroutine.resume(self.frameCoroutine)
    end

    if math.abs(time - audio:tell()) > 0.1 then
        audio:seek(time)
    end
end

function state:draw()
    local curFrame = math.max(math.floor(time * fps), 1)
    local tex = self.frames[curFrame]
    if tex then
        if lastCurFrame ~= curFrame then
            lastCurFrame = curFrame
            self.texture = tex
        end
        love.graphics.draw(self.texture, 0, 0, 0, love.graphics.getWidth() / width, love.graphics.getHeight() / height)
    end
    love.graphics.print(#self.frames .. "\n" .. curFrame, 0, 0)
end

return state
