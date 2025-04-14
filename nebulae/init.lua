local nebulae = {
    pluginDir = "plugins",
}
local shared = require("nebulae.shared")
shared.nebulae = nebulae

function nebulae.req()
    require("nebulae.GraphicsManager")
    require("nebulae.Project")
    require("nebulae.Player")
    require("nebulae.Renderer")
    require("nebulae.TextRender")
    require("nebulae.ProjectPluginManager")
    require("nebulae.AudioManager")
    require("nebulae.KeyframeManager")
end

return nebulae
