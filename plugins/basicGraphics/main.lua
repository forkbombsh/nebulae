-- basic plugin for basic things
local basic = {}
local cachedImages = {}

local validModes = { line = "line", fill = "fill", [0] = "line", [1] = "fill" }

local function getMode(mode)
    return validModes[(type(mode) == "string" and mode:lower() or mode)] or "fill"
end

function basic:init(project)
    local graphicsManager = project.graphicsManager
    graphicsManager:registerObjectType({
        name = "rectangle",
        beautyName = "Rectangle",
        description = "A simple rectangle.",
        args = {
            width = {
                type = "number",
                description = "The width of the rectangle.",
                optional = false
            },
            height = {
                type = "number",
                description = "The height of the rectangle.",
                optional = false
            },
            mode = {
                type = "string",
                description = "Can either be 'fill' or 'line'",
                options = { "fill", "line" },
                optional = true
            },
            lineWidth = {
                type = "number",
                description = "Only applies when the mode is 'line'.",
                optional = true
            }
        },
        scaleable = {
            x = true,
            y = true,
            width = true,
            height = true,
            lineWidth = true
        },
        init = function(obj)
            local width = obj.width or 100
            local height = obj.height or 100
            local mode = getMode(obj.mode)
            local lineWidth = obj.lineWidth
            return {
                width = width,
                height = height,
                mode = mode,
                creatorSelectOffset = 0,
                lineWidth = lineWidth
            }
        end,
        draw = function(obj)
            love.graphics.setColor(obj.color or { 1, 1, 1, 1 })
            local lineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(tonumber(obj.lineWidth) or 1)
            love.graphics.rectangle(obj.mode, obj.x, obj.y, obj.width, obj.height)
            love.graphics.setLineWidth(lineWidth)
        end
    })

    graphicsManager:registerObjectType({
        name = "circle",
        beautyName = "Circle",
        description = "A simple circle.",
        args = {
            radius = {
                type = "number",
                description = "The radius of the circle.",
                optional = false
            },
            mode = {
                type = "string",
                description = "Can either be 'fill' or 'line'",
                options = { "fill", "line" },
                optional = true
            },
            lineWidth = {
                type = "number",
                description = "Only applies when the mode is 'line'.",
                optional = true
            }
        },
        scaleable = {
            x = true,
            y = true,
            radius = true,
            lineWidth = true
        },
        init = function(obj)
            local radius = obj.radius or 100
            local mode = getMode(obj.mode)
            local lineWidth = obj.lineWidth
            return {
                radius = radius,
                width = radius * 2,
                height = radius * 2,
                selectPositionOffsetX = -0.5,
                selectPositionOffsetY = -0.5,
                mode = mode,
                lineWidth = lineWidth
            }
        end,
        draw = function(obj)
            love.graphics.setColor(obj.color or { 1, 1, 1, 1 })
            local lineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(tonumber(obj.lineWidth) or 1)
            love.graphics.circle(obj.mode, obj.x, obj.y, obj.radius)
            love.graphics.setLineWidth(lineWidth)
        end
    })

    graphicsManager:registerObjectType({
        name = "image",
        beautyName = "Image",
        description = "An image.",
        args = {
            image = {
                type = "string",
                description = "The filename of the image.",
                optional = false
            }
        },
        scaleable = {
            x = true,
            y = true
        },
        init = function(obj, project)
            local cached = cachedImages[obj.image]
            local name = obj.image
            if not cached then
                local success
                success, cached = pcall(love.graphics.newImage, "projects/" .. project.name .. "/" .. obj.image)
                if success then
                    cachedImages[obj.image] = cached
                    obj.image = cached
                else
                    print("Failed to load image: " .. (name or "unknown"))
                    obj.image = love.graphics.newImage(love.image.newImageData(1, 1)) -- Fallback to a blank image
                end
            else
                obj.image = cached
            end
            return {
                image = obj.image,
                name = name,
            }
        end,
        draw = function(obj)
            love.graphics.setColor(obj.color or { 1, 1, 1, 1 })
            love.graphics.draw(obj.image, obj.x, obj.y)
        end,
        unload = function(obj)
            cachedImages[obj.name] = nil
        end
    })

    graphicsManager:registerObjectType({
        name = "text",
        beautyName = "Text",
        description = "Text.",
        args = {
            text = {
                type = "string",
                description = "The text to render.",
                optional = false
            },
            size = {
                type = "number",
                description = "The size of the text in pixels.",
                optional = false
            },
            quality = {
                type = "number",
                description =
                "The quality of the text. (e.g. 25 quality and 25 size = 100% quality, 50 quality and 25 size = 200% quality, etc.)",
                optional = false
            },
            spacing = {
                type = "number",
                description = "The spacing between characters.",
                optional = true
            },
            font = {
                type = "string",
                description = "The font to use.",
                optional = true
            }
        },
        scaleable = {
            x = true,
            y = true,
            quality = true,
            size = true
        },
        init = function(obj, project)
            local x = obj.x or 100
            local y = obj.y or 100
            local text = obj.text or "Sample Text"
            local quality = obj.quality or 20
            local size = obj.size or 20
            local spacing = obj.spacing or 0
            local font = (type(obj.font) == "string" and ("projects/%s/%s"):format(project.name, obj.font) or nil)
            local textObject = TextRender(text, x, y, size, quality, spacing, font, project)
            return {
                text = text,
                quality = quality,
                size = size,
                spacing = spacing,
                font = font,
                textObject = textObject
            }
        end,
        draw = function(obj)
            love.graphics.setColor(obj.color or { 1, 1, 1, 1 })
            obj.textObject:draw()
        end,
        update = function(obj)
            obj.textObject.x = obj.x
            obj.textObject.y = obj.y
            obj.textObject.size = obj.size
            obj.textObject.quality = obj.quality
            obj.textObject.spacing = obj.spacing
        end
    })

    graphicsManager:registerObjectType({
        name = "video",
        beautyName = "Video",
        description = "A video.",
        args = {
            video = {
                type = "string",
                description = "The filename of the video.",
                optional = false
            }
        },
        scaleable = {
            x = true,
            y = true
        },
        init = function(obj, project)
            local tempPath = TempPath
            local filename = obj.video
            local baseName = filename:match("(.+)%..+")
            local videoOnlyAudio = baseName .. "-aud.wav"
            local videoNoAudio = baseName .. "-vid.mp4"
            local audioPathFull = tempPath .. "/" .. videoOnlyAudio
            local videoPathFull = tempPath .. "/" .. videoNoAudio
            if not NativeFS.getInfo(audioPathFull) or not NativeFS.getInfo(videoPathFull) then
                os.execute(("ffmpeg -i \"%s\" -vn -acodec pcm_s16le -ar 48000 -ac 2 \"%s\" -an -vcodec copy \"%s\" -y")
                    :format(project.folder .. "/" .. filename, audioPathFull, videoPathFull))
            end
            local audioPathFile = love.filesystem.openNativeFile(audioPathFull, "r")
            local videoPathFile = love.filesystem.openNativeFile(videoPathFull, "r")
            local video = love.graphics.newVideo(videoPathFile)
            local source = video:getSource()
            if source then
                source:setVolume(0)
            end
            local videoObject = Video(obj, project, video)
            local soundData = project.audioManager:loadSoundData(audioPathFile)
            local sound = Sound({
                soundData = soundData,
                startTime = obj.startTime,
                endTime = obj.endTime,
                audioTime = videoObject.videoTime
            })
            sound.path = videoOnlyAudio
            project.audioManager:addRTSound(sound)
            videoObject.audio = sound
            project.videoManager:addVideo(videoObject)
            return {
                video = video,
                width = video:getWidth(),
                height = video:getHeight(),
                videoObject = videoObject
            }
        end,
        draw = function(obj)
            love.graphics.setColor(obj.color or { 1, 1, 1, 1 })
            love.graphics.draw(obj.video, obj.x, obj.y)
        end,
        unload = function(obj)
            obj.videoObject:unload()
        end
    })
end

function basic:onUnload()
end

return basic
