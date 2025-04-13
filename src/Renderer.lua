local socket = require("socket")
Renderer = {
    isRendering = false,
    canvas = nil,
    pipe = nil,
    isEncoding = false,
    width = 1280,
    height = 720,
    framerate = 60,
    exportingPresets = { "ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow" },
    exportingPresetID = 1,
    crf = 18,
    timeTakenToRender = 0,
    exportingThread = love.thread.newThread([[
			require "love.image"
			require "love.event"

            local useh264 = select("#", ...) >= 8
			
			local pipe
			
			if useh264 then
				-- If it is using H.264 encoding, it sends more parameters
				
				pipe = io.popen(
					string.format("\"\"%s\" -f image2pipe -r %d -s %dx%d -c:v rawvideo -pix_fmt rgba -frame_size %d -i - -vf colormatrix=bt601:bt709 -pix_fmt yuv420p -c:v libx264 -crf %d -preset:v %s -y \"%s\"\"", ...), "wb"
				)
			else
				pipe = io.popen(
					string.format("\"\"%s\" -f image2pipe -r %d -s %dx%d -c:v rawvideo -pix_fmt rgba -frame_size %d -i - -c:v png -y \"%s\"\"", ...), "wb"
				)
			end
			
			while not love.thread.getChannel("renderingStopped"):peek() or love.thread.getChannel("imageData"):getCount() > 0 do
				
				local imageData = love.thread.getChannel("imageData"):pop()
				
				if imageData then
					pipe:write(imageData:getString())
					
					imageData:release()
				end
			end
			
			love.thread.getChannel("renderingStopped"):pop()
			
			pipe:read('*a')	-- wait for the pipe
			pipe:close()
		]])
}

function Renderer:start(w, h, fps, project, onFinish)
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
    self.tempVidPath = string.format("%s/%s/%s-temp.mp4", GetDirectory(), "renders", os.date("%Y%m%d-%H%M%S"))
    self.vidPath = string.format("%s/%s/%s.mp4", GetDirectory(), "renders", os.date("%Y%m%d-%H%M%S"))
    self.audioPath = string.format("%s/%s/%s.wav", GetDirectory(), "renders", os.date("%Y%m%d-%H%M%S"))
    self.exportingThread:start(
        "ffmpeg",
        fps,
        w, h,
        4 * w * h,
        self.crf, self.exportingPresets[self.exportingPresetID],
        self.tempVidPath
    )
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
        while love.thread.getChannel("imageData"):getCount() > 3 do love.timer.sleep(0.001) end
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
                local combinedSoundData = audioManager:combineSoundDatas(audioManager.sounds)
                ForceDraw(function()
                    love.graphics.clear()
                    love.graphics.printf("Encoding audio...", BigFontArial, 0, 0, love.graphics.getWidth(), "center")
                end)
                local encoded = audioManager:encodeSoundDataWav(combinedSoundData, player.time)
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
            love.timer.sleep(0.5)
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
