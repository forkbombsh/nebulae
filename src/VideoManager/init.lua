require("src.VideoManager.Video")
VideoManager = Class("VideoManager")

function VideoManager:initialize(project)
    print("init video manager")
    self.videos = {}
    self.project = project
    self.player = self.project.player
end

function VideoManager:addVideoToProject(video, filename)
    print(self.project.folder)
end

function VideoManager:addVideo(video)
    video.project = self.project
    table.insert(self.videos, video)
end

function VideoManager:update()
    for i, v in ipairs(self.videos) do
        if type(v.update) == "function" then
            v:update()
        end
    end
end

function VideoManager:unload()
end