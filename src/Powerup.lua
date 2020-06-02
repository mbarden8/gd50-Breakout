--[[
    GD50
    Breakout Remake

    --Powerup Class--

    Author: Maxfield Barden
    mbarden8@vt.edu

    Represents a powerup object that will fall to the player randomly.
    Once the player receives the powerup, two more identical balls will
    spawn for the player and behave identically to the original.
    Once the VictoryState is achieved, the balls should go away and reset
    so there is only one active.
]]

Powerup = Class{}

function Powerup:init(skin)
    -- positional variables
    self.width = 16
    self.height = 16

    -- keep track of our x and y velocities
    self.dy = 50
    self.dx = 15

    -- where the powerup will spawn
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 15

    -- this will be the skin of our powerup which is indexed from 
    -- our table of quads
    self.skin = skin

end

function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the powerup next to the ball, will change later this is only
    for testing purposes
]]

function Powerup:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- allow powerup to bounce off walls
    if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.x >= VIRTUAL_WIDTH - 8 then
        self.x = VIRTUAL_WIDTH - 8
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.y <= 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end
end

--[[
    Render the powerup on screen
]]
function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin], 
        self.x, self.y)
end