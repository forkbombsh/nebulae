-- ProjectPluginManager.lua
ProjectPluginManager = Class("PluginManager")

function ProjectPluginManager:initialize(project, pluginDir)
    print("init plugin manager")
    self.plugins = {}
    self.loadedPlugins = {}
    self.project = project
    self.pluginDir = pluginDir or "plugins"
end

function ProjectPluginManager:callPluginFunction(pluginName, name, ...)
    local plugin = self.plugins[pluginName]
    if type(plugin) == "table" and type(plugin[name]) == "function" then
        return plugin[name](plugin, ...)
    end
end

function ProjectPluginManager:loadAllPlugins()
    for _, pluginName in ipairs(love.filesystem.getDirectoryItems("plugins")) do
        local info = love.filesystem.getInfo("plugins/" .. pluginName)
        if info.type == "directory" then
            self:loadPlugin(pluginName)
        end
    end
end

function ProjectPluginManager:loadPlugin(pluginName)
    -- Check if the plugin is already loaded
    if self.loadedPlugins[pluginName] then
        print("Plugin '" .. pluginName .. "' is already loaded.")
        return
    end

    -- Load plugin meta.json
    local metaPath = "plugins/" .. pluginName .. "/meta.json"
    local meta = self:loadMeta(metaPath)
    if not meta then
        print("Failed to load meta.json for plugin: " .. pluginName)
        return
    end

    for i, v in ipairs(meta.dependencies) do
        self:loadPlugin(v)
    end

    -- Load the plugin entry file (i.e., the main Lua file)
    local entryPath = "plugins." .. pluginName .. "." .. meta.entry
    local success, plugin = pcall(require, entryPath)
    if success then
        -- Register the plugin and mark it as loaded
        if type(plugin) ~= "table" then
            -- plugin = {}
            return print("Failed to load plugin: " ..
                pluginName .. ", error: Plugin is supposed to return a table, not a " .. type(plugin) .. ".")
        end
        self.plugins[pluginName] = plugin
        self.loadedPlugins[pluginName] = true
        self:callPluginFunction(pluginName, "init", self.project)
        print("Successfully loaded plugin: " .. pluginName)
    else
        print("Failed to load plugin: " .. pluginName .. ", error: " .. plugin)
    end
end

function ProjectPluginManager:loadMeta(metaPath)
    local metaFileContent = love.filesystem.read(metaPath)
    if not metaFileContent then
        print("Failed to read meta file: " .. metaPath)
        return nil
    end
    local success, meta = pcall(Json.decode, metaFileContent)
    if not success then
        print("Failed to decode meta file: " .. metaPath)
        return nil
    end
    return meta
end

function ProjectPluginManager:unload()
    for pluginName, plugin in pairs(self.plugins) do
        self:callPluginFunction(pluginName, "unload")
    end
    self.plugins = nil
    self.loadedPlugins = nil
end
