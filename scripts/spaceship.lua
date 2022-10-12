local g = require("scripts.global")

local ship = {}

local acceleration = 80
local deceleration = 100
local max_speed = 120
local rotation_speed = 180

local input = vmath.vector3()
local speed = 0
local missile_move_amount = g.vector_up * 400

local rot_amount
local move_amount

local impact = false

local ray_end = vmath.vector3(100, 100, 0)

local ship_hit_result = {}
local ship_missile_hit_result = {}
local ray_result = {}
local collectable_result = {}

local function delete_projectile(self, url, property)
    go.delete(url)
end

local function fire_projectile()
    local missile = factory.create(g.factories.MISSILE, g.spaceship.pos, g.spaceship.rot)
    local target = g.spaceship.pos + vmath.rotate(g.spaceship.rot, missile_move_amount)
    go.animate(missile, "position", go.PLAYBACK_ONCE_FORWARD, target, go.EASING_LINEAR, 3, 0, delete_projectile)
end

function ship.init()
    msg.post("/laser", "disable")

    g.spaceship.url = msg.url("/spaceship")
    g.spaceship.sprite = msg.url("/spaceship#ship")

    g.spaceship.pos.x = g.screen_width / 2
    g.spaceship.pos.y = g.screen_height / 2
    g.spaceship.pos.z = 0

    g.spaceship.rot = go.get_rotation(g.spaceship.url)

    go.set_position(vmath.vector3(g.spaceship.pos.x, g.spaceship.pos.y, g.spaceship.pos.z), g.spaceship.url)
    go.set(g.spaceship.sprite, "cursor", 0.5)

    g.spaceship.enemy_aabb_id = aabb.insert_gameobject(g.enemy_group_id, g.spaceship.url, 10, 10)
    g.spaceship.enemy_missile_aabb_id = aabb.insert_gameobject(g.enemy_missile_group_id, g.spaceship.url, 10, 10)
    g.spaceship.collectable_aabb_id = aabb.insert_gameobject(g.collectable_group_id, g.spaceship.url, 10, 10)

    input = vmath.vector3()
    speed = 0
    timer.delay(0.12, true, fire_projectile)
end

local function dispatch_ray()
    msg.post("/laser", "enable")

    ray_end = g.spaceship.pos + vmath.rotate(g.spaceship.rot, g.vector_up * 70)
    ray_result = aabb.raycast(g.enemy_group_id, g.spaceship.pos.x, g.spaceship.pos.y, ray_end.x, ray_end.y)

    if ray_result then
        for i = 1, #ray_result do
            if g.enemies[ray_result[i]] then
                msg.post(g.enemies[ray_result[i]].url, "take_damage")
            end
        end
    end
end

function ship.input(action_id, action)
    if action_id == g.move.LASER then
        dispatch_ray()
    end

    if action_id == g.move.LASER and action.released then
        msg.post("/laser", "disable")
    end

    if action_id == g.move.UP then
        input.y = 1
    elseif action_id == g.move.DOWN then
        input.y = -1
    elseif action_id == g.move.LEFT then
        go.set(g.spaceship.sprite, "cursor", 0.0)
        input.x = 1
    elseif action_id == g.move.RIGHT then
        go.set(g.spaceship.sprite, "cursor", 1.0)
        input.x = -1
    end

    if action.released then
        go.set(g.spaceship.sprite, "cursor", 0.5)
    end
end

local function hit_anim()
    if g.shield_v.x > 0 then

        if impact == false then
            msg.post(g.hud_url, "take_damage")
            impact = true
            sprite.play_flipbook("/shield#sprite", "ship_shield", function()
                impact = false
            end)
        end

    else

        if impact == false then
            msg.post(g.hud_url, "take_damage")
            impact = true
            local explode = factory.create(g.factories.EXPLODE, g.spaceship.pos)
            -- go.set_parent(explode, g.spaceship.url)
            sprite.play_flipbook(explode, "enemy_impact", function()
                go.delete(explode)
                impact = false
                if g.life_v.x <= 0 then
                    msg.post(g.proxy_url, "the_end")
                end
            end)
        end

    end
end

local function check_enemy_missile_hit()
    ship_missile_hit_result = aabb.query_id(g.enemy_missile_group_id, g.spaceship.enemy_missile_aabb_id)

    if ship_missile_hit_result then
        for i = 1, #ship_missile_hit_result do
            if g.enemy_missiles[ship_missile_hit_result[i]] then
                go.delete(g.enemy_missiles[ship_missile_hit_result[i]].url)
                hit_anim()
            end
        end
    end
end

local function check_enemy_hit()
    ship_hit_result = aabb.query_id(g.enemy_group_id, g.spaceship.enemy_aabb_id)

    if ship_hit_result then
        for i = 1, #ship_hit_result do
            if g.enemies[ship_hit_result[i]] then
                msg.post(g.enemies[ship_hit_result[i]].url, "take_damage")
                hit_anim()
            end
        end
    end
end

local function check_collectable()
    collectable_result = aabb.query_id(g.collectable_group_id, g.spaceship.collectable_aabb_id)

    if collectable_result then
        for i = 1, #collectable_result do
            if g.collectables[collectable_result[i]] and g.collectables[collectable_result[i]].active then
                g.collectables[collectable_result[i]].active = false
                msg.post(g.hud_url, "collect")
                msg.post(g.collectables[collectable_result[i]].url, "collect")
            end
        end
    end
end

local function ship_position(dt)
    if input.y > 0 then
        speed = speed + acceleration * dt
        speed = math.min(speed, max_speed)
    else
        speed = speed - deceleration * dt
        speed = math.max(speed, 0)
    end

    rot_amount = math.rad(rotation_speed * input.x * dt)
    g.spaceship.rot = g.spaceship.rot * vmath.quat_rotation_z(rot_amount)
    go.set_rotation(g.spaceship.rot, g.spaceship.url)

    move_amount = g.vector_up * speed * dt

    g.spaceship.pos = g.spaceship.pos + vmath.rotate(g.spaceship.rot, move_amount)

    if g.spaceship.pos.y > g.screen_height then
        g.spaceship.pos.y = 0
    elseif g.spaceship.pos.y < 0 then
        g.spaceship.pos.y = g.screen_height
    end

    if g.spaceship.pos.x > g.screen_width then
        g.spaceship.pos.x = 0
    elseif g.spaceship.pos.x < 0 then
        g.spaceship.pos.x = g.screen_width
    end

    go.set_position(g.spaceship.pos, g.spaceship.url)
    go.set_position(vmath.vector3(-1*(g.spaceship.pos.x/10),-1*(g.spaceship.pos.y/10), 0), "/back")

    input = vmath.vector3()
end

function ship.update(dt)
    ship_position(dt)
    check_enemy_hit()
    check_enemy_missile_hit()
    check_collectable()
end

return ship
