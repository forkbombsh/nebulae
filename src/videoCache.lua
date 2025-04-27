local path, cached = ...
local logsThread = love.thread.getChannel("logs")

logsThread:push({ "caching", path })

local json = require("lib.json")

require("love.filesystem")
require("love.data")

function ExecMath(code)
    -- Create a restricted environment (sandbox)
    local sandbox_env = {}
    setmetatable(sandbox_env, {
        __index = function(_, key)
            error("Access to '" .. key .. "' is restricted!", 2)
        end
    })

    if type(code) == "string" then
        -- Load the code from the string
        local func, loadErr = loadstring("return " .. code)
        if not func then
            return nil, "Error loading code: " .. loadErr
        end

        -- Set environment to sandbox and execute
        setfenv(func, sandbox_env)
        local ok, result = pcall(func)
        return result, ok
    else
        error("Expected string, got " .. type(code))
    end
end

local cacheChannel = love.thread.getChannel("cache")

local bruh = io.popen(('ffprobe -v quiet -print_format json -show_format -show_streams "%s"'):format(path))
local output = bruh:read("*a")
bruh:close()
if not output or output == "" then
    return nil, "Empty output from FFprobe"
end

local ok, videoInfo = pcall(json.decode, output)
if not ok then
    return nil, "Error decoding JSON: " .. tostring(videoInfo)
end

local hashid = love.data.encode("string", "hex", love.data.hash("md5", path))

if cached[hashid] then
    logsThread:push(hashid .. " is cached")
    return
end

if type(videoInfo) == "table" and type(videoInfo.streams) == "table" then
    local videoStream = videoInfo.streams[1]
    local duration = tonumber(videoInfo.format.duration)
    if videoStream then
        local width, height = videoStream.width, videoStream.height
        local framerate = ExecMath(videoStream.avg_frame_rate)
        local thumbnailPath = "cached/" .. hashid .. "/thumbnail.png"
        love.filesystem.createDirectory("cached/" .. hashid)
        if type(width) ~= "number" or type(height) ~= "number" or type(duration) ~= "number" or type(framerate) ~= "number" then
            return logsThread:push("Couldn't cache video. Maybe this was because there's some invalid values?")
        end
        love.filesystem.write("cached/" .. hashid .. "/info.json", json.encode({
            width = width,
            height = height,
            duration = duration,
            framerate = framerate
        }))
        local thumbnailTime = math.min(53, duration - 1)
        thumbnailTime = math.max(thumbnailTime, 0)
        thumbnailTime = thumbnailTime / 2
        local hours = math.floor(thumbnailTime / 3600)
        local minutes = math.floor((thumbnailTime % 3600) / 60)
        local seconds = math.floor(thumbnailTime % 60)
        local timestamp = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        os.execute(("ffmpeg -ss %s -i \"%s\" -frames:v 1 \"%s\" -y"):format(
            timestamp,
            path,
            love.filesystem.getSaveDirectory() .. "/" .. thumbnailPath
        ))
        cacheChannel:push(hashid)
    end
else
    logsThread:push("Couldn't cache video. Maybe this was because it doesn't exist?")
end
