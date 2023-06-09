function love.load()
    love.window.setMode(1000, 768)

    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'

    cam = cameraFile()

    sounds = {}
    sounds.jump = love.audio.newSource("audio/jump.wav", "static")
    sounds.shoot = love.audio.newSource("audio/shoot.wav", "static")
    sounds.nextLevel = love.audio.newSource("audio/nextLevel.wav", "static")
    sounds.hurt = love.audio.newSource("audio/hurt.wav", "static")
    sounds.music = love.audio.newSource("audio/backSound.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(1)

    sounds.music:play()

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/ninjaPlayer.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemyRed.png')
    sprites.bullet = love.graphics.newImage('sprites/Saw.png')
    sprites.background = love.graphics.newImage('sprites/spaceBackground.jpg')
    

    local grid = anim8.newGrid(182, 242, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(203, 173, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-10',1), 0.05)
    animations.jump = anim8.newAnimation(grid('1-10',2), 0.05)
    animations.run = anim8.newAnimation(grid('1-10',3), 0.05)
    animations.enemy = anim8.newAnimation(enemyGrid('1-8',1), 0.05)

    wf = require 'libraries/windfield/windfield'
    world = wf.newWorld(0, 800, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass('Platform')
    world:addCollisionClass('Player'--[[, {ignores = {'Platform'}}]])
    world:addCollisionClass('Danger')
    world:addCollisionClass('Bullet')

    require('player')
    require('enemy')
    require('bullet')
    require('libraries/show')
    

    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = "Danger"})
    dangerZone:setType('static')

    platforms = {}

    flagX = 0
    flagY = 0

    saveData = {}
    saveData.currentLevel = "level0"

    if love.filesystem.getInfo("data.lua") then
        local data = love.filesystem.load("data.lua")
        data()
    end

    loadMap(saveData.currentLevel)
end

function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    playerUpdate(dt)
    updateEnemies(dt)
    updateBullet(dt)

   

    local px, py = player:getPosition()
    cam:lookAt(px, love.graphics.getHeight()/2)

   

    local colliders = world:queryCircleArea(flagX, flagY, 10, {'Player'})
    if #colliders > 0 then
        sounds.nextLevel:play()
        if saveData.currentLevel == "level0" then
            loadMap("level1")
        elseif saveData.currentLevel == "level1" then
            loadMap("level2")    
        elseif saveData.currentLevel == "level2" then
            loadMap("level0")
        end
    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)
    
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        drawPlayer()
        drawBullet()
        drawEnemies()
        
    cam:detach()

    if saveData.currentLevel == "level0" then
        love.graphics.rectangle("fill", 100,400, 800,200, 50,50)
        --local coloredtext = love.graphics.newText( "Hello, World!")
        local text = {
            
            {0, 0, 255, 255}, "Welcome to the Ninja game!\nYou have to reach the flag to go to the next level. \nAvoid the enemies or defeat them.\n" ,
            {134,0 , 130, 196}, "Use the arrow keys to move and jump. \nPress 's' to shoot. Press 'r' to restart the game.\n",
            {255, 0, 0, 255}, "Good luck!"
        }
        love.graphics.print(text, 130, 420, 0, 2, 2, 0, 0, 0, 0)
    end
    
end

function love.keypressed(key)
    if key == 'up' then
        if player.grounded then
            player:applyLinearImpulse(0, -4000)
            sounds.jump:play()
        end
    end
    if key == 'r' then
        loadMap("level0")
    end

    if key == 's' then
        spawnBullet()
        sounds.shoot:play()
    end
end
   

-- function love.mousepressed(x, y, button)
--     if button == 1 then
--         local colliders = world:queryCircleArea(x, y, 200, {'Platform', 'Danger',})
--         for i,c in ipairs(colliders) do
--             c:destroy()
--         end
--     end
-- end

function spawnPlatform(x, y, width, height)
    local platform = world:newRectangleCollider(x, y, width, height, {collision_class = "Platform"})
    platform:setType('static')
    table.insert(platforms, platform)
end


  

function destroyAll()
    local i = #platforms
    while i > -1 do
        if platforms[i] ~= nil then
            platforms[i]:destroy()
        end
        table.remove(platforms, i)
        i = i -1
    end

    local i = #enemies
    while i > -1 do
        if enemies[i] ~= nil then
            enemies[i]:destroy()
        end
        table.remove(enemies, i)
        i = i -1
    end
end

function loadMap(mapName)
    saveData.currentLevel = mapName
    love.filesystem.write("data.lua", table.show(saveData, "saveData"))
    
    destroyAll()
    gameMap = sti("maps/" .. mapName .. ".lua")
    
    for i, obj in pairs(gameMap.layers["Start"].objects) do
        playerStartX = obj.x
        playerStartY = obj.y
    end
    player:setPosition(playerStartX, playerStartY)
    
    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    

    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x
        flagY = obj.y
    end

    if  mapName~="level0" then
        
        for i, obj in pairs(gameMap.layers["Enemies"].objects) do
            spawnEnemy(obj.x, obj.y)
        end
    end
end