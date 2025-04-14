Tween = Class("Tween")

-- Linear interpolation function
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Deep copy only number values, recursively, with cycle protection
local function deepCopyNumbersOnly(tbl, seen)
    seen = seen or {}
    if seen[tbl] then return seen[tbl] end

    local result = {}
    seen[tbl] = result

    for key, value in pairs(tbl) do
        if type(value) == "number" then
            result[key] = value
        elseif type(value) == "table" then
            result[key] = deepCopyNumbersOnly(value, seen)
        end
    end

    return result
end

-- Recursively interpolate numeric fields in old using initial and target
local function tweenRecursive(old, initial, target, t)
    for key, value in pairs(target) do
        if type(value) == "number" then
            if initial[key] ~= nil then
                old[key] = lerp(initial[key], value, t)
            end
        elseif type(value) == "table" then
            old[key] = old[key] or {}
            tweenRecursive(old[key], initial[key] or {}, value, t)
        end
    end
end

-- Tween class constructor
function Tween:initialize(oldObj, newObj, startTime, endTime, controlpoints)
    self.isGood = false
    self.controlpoints = controlpoints
    self.currentTime = 0
    self.oldObj = oldObj
    self.newObj = newObj
    self.startTime = startTime
    self.endTime = endTime
    self.initialValues = deepCopyNumbersOnly(oldObj) -- Safe copy of initial numeric values
end

-- Visualize the Bezier curve (for debugging)
function Tween:visualise(x, y)
    if self.isGood then
        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.line(self.bezierCurve:render())
        love.graphics.pop()
    end
end

-- Update function to tween based on current time
function Tween:update(currentTime)
    if not self.newObj or not self.oldObj or not self.isGood then return end
    self.currentTime = currentTime

    local progress = math.min(math.max((currentTime - self.startTime) / (self.endTime - self.startTime), 0), 1)
    local _, curveProgress = self.bezierCurve:evaluate(progress)
    local t = curveProgress / 100

    tweenRecursive(self.oldObj, self.initialValues, self.newObj, t)
end
