
require('player')
require('enemy')


bullets = {}

function spawnBullet()
    local bullet = {}
    local px, py = player:getPosition()
    bullet.x =px  
    bullet.y = py+15
    bullet.speed = 500
    bullet.dead = false
    bullet.direction = player.direction
    table.insert(bullets, bullet)
end




function updateBullet(dt)
    for i,b in ipairs(bullets) do
       b.x = b.x + (b.direction  * b.speed * dt)
    end

    for i=#bullets, 1, -1 do
        local b = bullets[i]
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end
end

function drawBullet()
    for i,b in ipairs(bullets) do
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, nil, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
    end
end