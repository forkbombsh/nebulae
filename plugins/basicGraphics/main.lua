-- basic (this would be the basic plugin for things like text, rectangle, etc.)
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
        init = function(obj)
            local points = obj.points
            if type(points) ~= "table" then
                points = { 0, 0, 5, 5, 2.5, 5 }
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
            love.graphics.polygon("fill", obj.points)
            love.graphics.setLineWidth(lineWidth)
        end
    })

    graphicsManager:registerObjectType({
        name = "2dperlinnoise",
        beautyName = "2D Perlin Noise",
        init = function(obj)
            local nx = type(obj.nx) == "number" and obj.nx or 1
            local ny = type(obj.ny) == "number" and obj.ny or obj.nx
            local seed = type(obj.seed) == "number" and obj.seed or 0
            local tileSize = type(obj.tileSize) == "number" and obj.tileSize or 1
            local width = type(obj.width) == "number" and obj.width or 100
            local height = type(obj.height) == "number" and obj.height or 100
            -- local seedX = type(obj.seedX) == "number" and obj.seedX or seed
            -- local seedY = type(obj.seedY) == "number" and obj.seedY or seed
            return {
                width = width,
                height = height,
                nx = nx,
                ny = ny,
                seed = seed,
                grid = {},
                tileSize = tileSize
            }
        end,
        update = function(dt, obj)
            obj.grid = {}
            for y = 1, obj.width do
                obj.grid[y] = {}
                for x = 1, obj.height do
                    obj.grid[y][x] = love.math.noise(obj.seed + .1 * x, obj.seed + .2 * y)
                end
            end
        end,
        draw = function(obj)
            local tileSize = obj.tileSize
            for y = 1, #obj.grid do
                for x = 1, #obj.grid[y] do
                    -- love.graphics.setColor(obj.grid[y][x], obj.grid[y][x], obj.grid[y][x])
                    love.graphics.rectangle("fill", x * tileSize, y * tileSize, tileSize - 1, tileSize - 1)
                end
            end
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
