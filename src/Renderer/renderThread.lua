require "love.image"
require "love.event"

print(...)

-- ykw h264 only idc

local pipe

pipe = io.popen(
    string.format(
        "\"\"%s\" -f image2pipe -r %d -s %dx%d -c:v rawvideo -pix_fmt rgba -frame_size %d -i - -vf colormatrix=bt601:bt709 -pix_fmt yuv420p %s -y \"%s\"\"",
        ...), "wb"
)

while not love.thread.getChannel("renderingStopped"):peek() or love.thread.getChannel("imageData"):getCount() > 0 do
    local imageData = love.thread.getChannel("imageData"):pop()

    if imageData then
        pipe:write(imageData:getString())

        imageData:release()
    end
end

love.thread.getChannel("renderingStopped"):pop()

pipe:read('*a') -- wait for the pipe
pipe:close()
