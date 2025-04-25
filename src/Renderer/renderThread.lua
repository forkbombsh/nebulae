require("love.image")
require("love.event")
local pipeCommand = ...

print(pipeCommand)

local renderingStoppedChannel = love.thread.getChannel("renderingStopped")

local pipe = io.popen(pipeCommand, "wb")

while true do
    if renderingStoppedChannel:peek() and love.thread.getChannel("imageData"):getCount() == 0 then
        break
    end

    local data = love.thread.getChannel("imageData"):pop()
    if data then
        local rawString = data:getString()
        pipe:write(rawString)
        data:release()
    end
end

renderingStoppedChannel:pop()

pipe:read('*a') -- wait for ffmpeg to finish
pipe:close()
