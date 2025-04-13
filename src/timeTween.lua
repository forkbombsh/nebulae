local timeTween = {}
timeTween.groups = {} -- Holds all tween groups

-- Lerp helper function
local function lerp(a, b, t)
    return a + (b - a) * t
end

local curves = {
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

function timeTween.convertTableToValid(curves)
    for _, values in pairs(curves) do
        local count = #values
        for i = count, 1, -1 do
            table.insert(values, i, (i - 1) / (count - 1) * 100)
        end
    end
end

function timeTween.convertToValid(curve)
    local count = #curve
    for i = count, 1, -1 do
        table.insert(curve, i, (i - 1) / (count - 1) * 100)
    end
    return curve
end