Player = Class("Player")

function Player:reset()
    self.time = 0
    self.speed = 1
    self.isPlaying = false
    self.isLooping = false
    self.events = {}
    self.isReversed = false
    self.duration = 0
    self._ = {}
    self._.lastTime = 0
    self.isMovingForward = true
end

function Player:initialize()
    print("init player")
    self:reset()
end

function Player:play()
    self.isPlaying = true
end

function Player:pause()
    self.isPlaying = false
end

function Player:stop()
    self.isPlaying = false
    self.time = 0
end

function Player:toggle()
    if self.isPlaying then
        self:pause()
    else
        self:play()
    end
end

function Player:update(dt)
    if self.isPlaying then
        self.time = self.time + (self.isReversed and -(dt * self.speed) or (dt * self.speed))
        for _, event in pairs(self.events) do
            if event.time <= self.time and not event.triggered then
                event.triggered = true
            end
        end
    end
    if self.time > self._.lastTime then
        self.isMovingForward = true
    else
        self.isMovingForward = false
    end
    self._.lastTime = self.time
end

function Player:seek(time)
    self.time = time
end

function Player:setSpeed(speed)
    self.speed = speed
end
