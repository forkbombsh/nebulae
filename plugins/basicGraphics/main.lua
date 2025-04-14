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
        description = "An image.",
        args = {
            image = {
                type = "string",
                description = "The filename of the image.",
                optional = false
            }
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
        end
    })

    graphicsManager:registerObjectType({
        name = "text",
        description = "Text.",
        args = {
            text = {
                type = "string",
                description = "The text to render.",
                optional = false
            },
            size = {
                type = "number",
                description = "The size of the text.",
                optional = false
            },
            quality = {
                type = "number",
                description = "The quality of the text.",
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
        name = "line",
        description = "A line between two or more points.",
        args = {
            points = {
                type = "table",
                subtype = "number",
                min = 2,
                description = "The points of the line.",
                optional = false
            },
            lineWidth = {
                type = "number",
                description = "The width of the line.",
                optional = true
            }
        },
        init = function(obj)
            local points = obj.points
            if type(points) ~= "table" then
                points = { 0, 0, 100, 100 }
            end
            return {
                points = points,
                lineWidth = obj.lineWidth
            }
        end,
        draw = function(obj)
            love.graphics.setColor(obj.color or { 1, 1, 1, 1 })
            local lineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(tonumber(obj.lineWidth) or 1)
            love.graphics.line(obj.points)
            love.graphics.setLineWidth(lineWidth)
        end
    })

    graphicsManager:registerObjectType({
        name = "polygon",
        description = "A polygon.",
        args = {
            points = {
                type = "table",
                subtype = "number",
                min = 3,
                description = "The points of the polygon.",
                optional = false
            },
            lineWidth = {
                type = "number",
                description = "Only applies when the mode is 'line'",
                optional = true
            }
        },
        init = function(obj)
            local points = obj.points
            if type(points) ~= "table" then
                points = { 0, 0, 5, 5, 2.5, 5 }
            end
            local mode = getMode(obj.mode)
            return {
                points = points,
                mode = mode,
                lineWidth = obj.lineWidth
            }
        end,
        draw = function(obj)
            love.graphics.setColor(obj.color or { 1, 1, 1, 1 })
            local lineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(tonumber(obj.lineWidth) or 1)
            love.graphics.polygon(onj.mode, obj.points)
            love.graphics.setLineWidth(lineWidth)
        end
    })
end

function basic:onUnload()
    for name, image in pairs(cachedImages) do
        image:release()
    end
    cachedImages = {}
end

return basic
