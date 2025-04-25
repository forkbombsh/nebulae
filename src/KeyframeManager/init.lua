require("src.KeyframeManager.Tween")
require("src.KeyframeManager.UI")
KeyframeManager = Class("KeyframeManager")

KeyframeManager.curves = {
    quadin = { 0, 8.5, 53, 100 },
    quadout = { 0, 100, 100, 100 },
    quadinout = { 0, 3, 95.5, 100 },
    cubicin = { 0, 5.5, 19, 100 },
    cubicout = { 0, 61, 100, 100 },
    cubicinout = { 0, 4.5, 100, 100 },
    quartin = { 0, 3, 22, 100 },
    quartout = { 0, 100, 100, 100 },
    quartinout = { 0, 0, 100, 100 },
    quintin = { 0, 5, 6, 100 },
    quintout = { 0, 100, 100, 100 },
    quintinout = { 0, 0, 100, 100 },
    expoin = { 0, 5, 3.5, 100 },
    expoout = { 0, 100, 100, 100 },
    expoinout = { 0, 0, 100, 100 },
    sinein = { 0, 0, 71.5, 100 },
    sineout = { 0, 57.5, 100, 100 },
    sineinout = { 0, 5, 95, 100 },
    circin = { 0, 4, 33.5, 100 },
    circout = { 0, 82, 100, 100 },
    circinout = { 0, 13.5, 86, 100 },
    backin = { 0, -28, 4.5, 100 },
    backout = { 0, 88.5, 127.5, 100 },
    backinout = { 0, -55, 155, 100 },
    elasticin = { 0, -60, 30, 100 },
    elasticout = { 0, 70, 160, 100 },
    elasticinout = { 0, -30, 130, 100 },
    linear = { 0, 100 }
}

function KeyframeManager:addTweenType(name, controlpoints)
    KeyframeManager.curves[name] = controlpoints
end

function KeyframeManager:removeTweenType(name)
    KeyframeManager.curves[name] = nil
end

function KeyframeManager:getCurve(name)
    return KeyframeManager.curves[name]
end

function KeyframeManager:easingToXYCurve(fn, steps)
    local curve = {}
    for i = 0, steps do
        local t = i / steps
        table.insert(curve, t * 100)     -- X
        table.insert(curve, fn(t) * 100) -- Y
    end
    return curve
end

function KeyframeManager:initialize()
    self.tweens = {}
end

function KeyframeManager:convertToValid(curve)
    local valid = {}
    local count = #curve
    for i = 1, count do
        table.insert(valid, (i - 1) / (count - 1) * 100)
        table.insert(valid, curve[i])
    end
    return valid
end

function KeyframeManager:addTween(tween)
    local bezierCurve
    if tween.skipConversion then
        bezierCurve = love.math.newBezierCurve(tween.controlpoints)
    else
        local validControlPoints = self:convertToValid(tween.controlpoints)
        bezierCurve = love.math.newBezierCurve(validControlPoints)
    end
    tween.bezierCurve = bezierCurve
    tween.isGood = true
    table.insert(self.tweens, tween)
end

function KeyframeManager:update(currentTime)
    for i, v in ipairs(self.tweens) do
        if currentTime >= v.startTime - 0.1 and currentTime <= v.endTime + 0.1 then
            v:update(currentTime)
        end
    end
end
