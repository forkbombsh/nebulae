local socket = require("socket")
Renderer = {
    isRendering = false,
    canvas = nil,
    pipe = nil,
    isEncoding = false,
    width = 1280,
    height = 720,
    framerate = 60,
    renderThings = {
        libx264 = {
            name = "libx264",
            description = "Software encoding (CPU)",
            args = "-c:v libx264 -crf %d -preset:v %s",
            types = {
                {
                    name = "crf",
                    type = "number"
                },
                {
                    name = "Preset",
                    type = "string",
                    options = { "ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow" }
                }
            },
            presets = { "ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow" },
            default = { 23, "ultrafast" }
        },
        h264_nvenc = {
            name = "h264_nvenc",
            description = "Hardware encoding for NVIDIA only",
            args = "-c:v h264_nvenc -cq %d -preset %s",
            types = {
                {
                    name = "cq",
                    type = "number"
                },
                {
                    name = "Preset",
                    type = "string",
                    options = { "p1", "p2", "p3", "p4", "p5", "p6", "p7" }
                }
            },
            presets = { "p1", "p2", "p3", "p4", "p5", "p6", "p7" },
            default = { 23, "p1" }
        },
        h264_amf = {
            name = "h264_amf",
            description = "Hardware encoding for AMD only",
            args = "-c:v h264_amf -b:v %dM -quality %s",
            types = {
                {
                    name = "Bitrate (Mbps)",
                    type = "number"
                },
                {
                    name = "Quality",
                    type = "string",
                    options = { "speed", "balanced", "quality" }
                }
            },
            default = { 10, "quality" },
            presets = { "speed", "balanced", "quality" }
        },
        vp9 = {
            name = "vp9",
            description = "VP9 encoding, very slow",
            args = "-c:v libvpx-vp9 -b:v %dM -deadline %s",
            types = {
                {
                    name = "Bitrate (Mbps)",
                    type = "number"
                },
                {
                    name = "Deadline",
                    type = "string",
                    options = { "best", "good", "realtime" }
                }
            },
            default = { 80, "good" },
            presets = { "best", "good", "realtime" }
        },
        av1 = {
            name = "av1",
            description = "AV1 encoding, very slow",
            args = "-c:v libaom-av1 -crf %d -b:v 0 -cpu-used=%s",
            types = {
                {
                    name = "CRF",
                    type = "number"
                },
                {
                    name = "Speed",
                    type = "number"
                }
            },
            default = { 28, 4 },
            presets = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
        },
        av1_nvenc = {
            name = "av1_nvenc",
            description = "AV1 encoding with NVIDIA hardware acceleration",
            args = "-c:v av1_nvenc -crf %d -b:v 0 -cpu-used=%s",
            types = {
                { name = "CRF",   type = "number" },
                { name = "Speed", type = "number" }
            },
            default = { 28, 4 },
            presets = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
        },
        av1_amf = {
            name = "av1_amf",
            description = "AV1 encoding with AMD hardware acceleration",
            args = "-c:v av1_amf -crf %d -b:v 0 -cpu-used=%s",
            types = {
                { name = "CRF",   type = "number" },
                { name = "Speed", type = "number" }
            },
            default = { 28, 4 },
            presets = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
        }
    },
    timeTakenToRender = 0,
    exportingThread = love.thread.newThread("src/Renderer/renderThread.lua")
}

function Renderer:start(w, h, fps, project, renderType, renderArgs, onFinish)
    print("Rendering audio...")
    local player = project.player
    player:stop()
    self.width = w
    self.height = h
    self.framerate = fps
    self.canvas = love.graphics.newCanvas(w, h)
    self.isRendering = true
    self.isEncoding = true
    self.crf = 18
    self.timeTakenToRender = 0
    self.startTime = socket.gettime()
    local date = os.date("%Y%m%d-%H%M%S")
    self.tempVidPath = string.format("%s/%s/%s-temp.mp4", GetDirectory(), "renders", date)
    self.vidPath = string.format("%s/%s/%s.mp4", GetDirectory(), "renders", date)
    self.audioPath = string.format("%s/%s/%s.wav", GetDirectory(), "renders", date)
    if self.renderThings[renderType.name] then
        self.renderType = renderType
    else
        self.renderType = self.renderThings.libx264
    end
    renderType = self.renderType
    local ffmpegArgs = renderType.args
    if type(renderArgs) == "table" and #renderArgs > 0 then
        local formattedArgs = ffmpegArgs
        if #renderArgs >= #renderType.types then
            for i, v in ipairs(renderArgs) do
                formattedArgs = string.format(formattedArgs, v)
            end
        elseif #renderArgs < #renderType.types then
            -- wtf some are nil
            for i, v in ipairs(renderArgs) do
                formattedArgs = string.format(ffmpegArgs, unpack(renderArgs))
            end
            for i, v in ipairs(renderType.types) do
                if i > #renderArgs then
                    formattedArgs = string.format(formattedArgs, v.default)
                end
            end
        end
        ffmpegArgs = formattedArgs
    else
        -- fallback
        ffmpegArgs = string.format(ffmpegArgs, unpack(renderType.default))
    end
    self.exportingThread:start(("\"\"%s\" -f image2pipe -framerate %d -s %dx%d -c:v rawvideo -pix_fmt rgba -frame_size %d -i - -vf colormatrix=bt601:bt709 -pix_fmt yuv420p %s -y -movflags +faststart \"%s\"\"")
        :format("ffmpeg",
            fps,
            w, h,
            4 * w * h,
            ffmpegArgs,
            self.tempVidPath))
    player.time = 0
    player:play()
    self.project = project
    self.onFinish = onFinish
end

function Renderer:update(dt)
    if self.isRendering and self.isEncoding then
        local project = self.project
        local player = project.player
        if player.time >= player.duration then
            self:finish()
        end
        self.timeTakenToRender = self.timeTakenToRender + dt
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1)
        project.graphicsManager:draw()
        love.graphics.setCanvas()
        local imageData = self.canvas:newImageData()
        while love.thread.getChannel("imageData"):getCount() > 3 do
            love.timer.sleep(0.001)
        end
        love.thread.getChannel("imageData"):push(imageData)
        imageData:release()
        local newDT = (1 / Renderer.framerate) * player.speed
        return newDT
    elseif self.isEncoding then
        local project = self.project
        local player = project.player
        local audioManager = project.audioManager
        if not self.exportingThread:isRunning() then
            self.isEncoding = false
            self.timeTakenToRender = socket.gettime() - self.startTime
            local hasAudio = #audioManager.sounds > 0
            if hasAudio then
                print("finished rendering")
                ForceDraw(function()
                    love.graphics.clear()
                    love.graphics.printf("Combining sound datas...", BigFontArial, 0, 0, love.graphics.getWidth(),
                        "center")
                end)
                local combinedSoundData = audioManager:combineSoundDatas(audioManager.sounds, player.duration)
                ForceDraw(function()
                    love.graphics.clear()
                    love.graphics.printf("Encoding audio...", BigFontArial, 0, 0, love.graphics.getWidth(), "center")
                end)
                local encoded = audioManager:encodeSoundDataWav(combinedSoundData)
                NativeFS.write(self.audioPath, encoded)
                ForceDraw(function()
                    love.graphics.clear()
                    love.graphics.printf("Merging audio and video...", BigFontArial, 0, 0, love.graphics.getWidth(),
                        "center")
                end)
                os.execute(("ffmpeg -i \"%s\" -i \"%s\" -c:v copy -c:a aac -strict experimental -shortest \"%s\"")
                    :format(
                        self.audioPath, self.tempVidPath, self.vidPath))
            else
                NativeFS.write("renders/" .. self.vidPath, NativeFS.read(self.tempVidPath))
            end
            ForceDraw(function()
                love.graphics.clear()
                love.graphics.printf("Cleaning up...", BigFontArial, 0, 0, love.graphics.getWidth(), "center")
            end)
            if hasAudio then
                NativeFS.remove(self.audioPath)
            end
            NativeFS.remove(self.tempVidPath)
            ForceDraw(function()
                love.graphics.clear()
                love.graphics.printf("Finished", BigFontArial, 0, 0, love.graphics.getWidth(),
                    "center")
            end)
            love.timer.sleep(0.25)
            if type(self.onFinish) == "function" then
                self.onFinish()
            end
            if self.quitAppAfter then
                love.event.quit()
            end
        end
        return dt
    end
    return dt
end

function Renderer:finish(isQuitApp)
    if self.isRendering then
        love.thread.getChannel("renderingStopped"):push(true)
        self.isRendering = false
        self.project.player:stop()
        print("Waiting for ffmpeg to finish up...")
        self.quitAppAfter = isQuitApp
    else
        print("not rendering")
    end
end
