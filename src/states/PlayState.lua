--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.keys = params.keys

    self.powerups = {}
    self.balls = {
        self.ball
    }

    self.ballTimer = 0
    self.keyTimer = 0

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end


    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        for j, ball in pairs(self.balls) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                if brick.locked and self.keys == 0 then
                    ::continue::
                else
                    brick:hit()
                    if brick.locked then
                        self.keys = self.keys - 1
                    end
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- increase paddle size; can't go above 3
                    if self.paddle.size < 3 then
                        self.paddle.size = self.paddle.size + 1
                        self.paddle.width = self.paddle.width + 32
                    end

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.balls[1],
                        recoverPoints = self.recoverPoints,
                        keys = 0
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                    
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                        
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                    
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                        
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                    
                -- bottom edge if no X collisions or top collision, last possibility
                else
                        
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- if all balls go below bounds, revert to serve state and decrease health

    for k, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, k)
            if next(self.balls) == nil then
                self.health = self.health - 1
                gSounds['hurt']:play()
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints,
                    keys = self.keys
                })
        
                if self.paddle.size >= 1 then
                    self.paddle.size = self.paddle.size - 1
                    self.paddle.width = self.paddle.width - 32
                end
            end

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- spawning the ball powerup
    self.ballTimer = self.ballTimer + dt
    local ball_spawn = math.random(5, 20)
    if self.ballTimer > ball_spawn then
        table.insert(self.powerups, Powerup(9))
        -- reset timer
        self.ballTimer = 0
    end

    -- spawning the key powerup
    self.keyTimer = self.keyTimer + dt
    local key_spawn = math.random(5, 20)
    if self.keys < 3 and self.keyTimer > key_spawn then
        table.insert(self.powerups, Powerup(10))
        self.keyTimer = 0
    end

    -- do the update for the powerups
    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
        if powerup:collides(self.paddle) then
            if powerup:powerType() == "two_balls" then
                gSounds['paddle-hit']:play()
                gSounds['ball-powerup']:play()
                table.remove(self.powerups, k)
                table.insert(self.balls, Ball(math.random(7), self.paddle.x + (self.paddle.width / 2) - 4, 
                 self.paddle.y - 8, math.random(-200, 200), math.random(-50, -60)))
                table.insert(self.balls, Ball(math.random(7), self.paddle.x + (self.paddle.width / 2) - 4, 
                 self.paddle.y - 8, math.random(-200, 200), math.random(-50, -60)))

            elseif powerup:powerType() == "key" then
                gSounds['paddle-hit']:play()
                table.remove(self.powerups, k)
                if self.keys < 3 then
                    self.keys = self.keys + 1
                    gSounds['key-pickup']:play()
                end
            end
        end

        if powerup.y > VIRTUAL_HEIGHT + 16 then
            table.remove(self.powerups, k)
        end
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render powerups
    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    -- render extra balls if there are any
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    self.paddle:render()

    renderScore(self.score)
    renderHealth(self.health)
    renderKeys(self.keys)
    if not self.paused then
        displayPause()
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf('Press "SPACE" to resume', 0, VIRTUAL_HEIGHT / 2 + 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end