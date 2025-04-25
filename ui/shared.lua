local shared = {}
local uniqueID = 0

function shared.getUniqueID()
    uniqueID = uniqueID + 1
    return uniqueID
end

return shared
