local global = {}

global.proxy_url = ""
global.hud_url = ""

global.shield_v = 0
global.life_v = 0

global.screen_width = 480
global.screen_height = 270
global.spaceship = {url = msg.url(), sprite = msg.url(), thruster = msg.url(), pos = vmath.vector3(), rot = vmath.vector3(), enemy_aabb_id = 0, enemy_missile_aabb_id = 0, collectable_aabb_id = 0}

global.vector_up = vmath.vector3(0, 1, 0)

global.move = {LEFT = hash("move_left"), RIGHT = hash("move_right"), UP = hash("move_up"), DOWN = hash("move_down"), LASER = hash("fire_laser")}

global.enemy_group_id = -1
global.enemy_missile_group_id = -1
global.collectable_group_id = -1

global.enemies = {}
global.missiles = {}
global.enemy_missiles = {}
global.collectables = {}

global.isPaused = false

global.elapsed_time_m = 0
global.elapsed_time_s = 0

global.factories = {
    ENEMY = msg.url("main:/factories#enemy"),
    EXPLODE = msg.url("main:/factories#explode"),
    MISSILE = msg.url("main:/factories#ship_projectile"),
    ENEMY_MISSILE = msg.url("main:/factories#enemy_projectile"),
    COLLECTABLE = msg.url("main:/factories#collectable")
}

local enemy_timer = function()
    timer.delay(rnd.double_range(0.1, 0.2), false, global.dispatch_enemy)
end

local function remove_enemy(self, url, property)
    go.delete(url)
end

function global.dispatch_enemy()
    local p = vmath.vector3()
    local endpos = vmath.vector3()

    if rnd.toss() == 1 then
        if rnd.toss() == 1 then
            p = vmath.vector3(rnd.range(0, global.screen_width), global.screen_height + 50, 0)
            endpos = vmath.vector3(rnd.range(0, global.screen_width), -50, 0)
        else
            p = vmath.vector3(rnd.range(0, global.screen_width), global.screen_height + 50, 0)
            endpos = vmath.vector3(rnd.range(0, global.screen_width), -50, 0)
        end
    else
        if rnd.toss() == 1 then
            p = vmath.vector3(-50, rnd.range(0, global.screen_height), 0)
            endpos = vmath.vector3(global.screen_width + 50, rnd.range(0, global.screen_height), 0)
        else
            p = vmath.vector3(global.screen_width + 50, rnd.range(0, global.screen_height), 0)
            endpos = vmath.vector3(-50, rnd.range(0, global.screen_height), 0)
        end
    end

    local angle = math.atan2(p.x - endpos.x, endpos.y - p.y)
    local enemy = factory.create(global.factories.ENEMY, p, vmath.quat_rotation_z(angle))
    go.animate(enemy, "position", go.PLAYBACK_ONCE_FORWARD, endpos, go.EASING_LINEAR, rnd.range(5, 20), 0, remove_enemy)

    enemy_timer()
end

function global.init()
    global.enemy_group_id = aabb.new_group()
    global.enemy_missile_group_id = aabb.new_group()
    global.collectable_group_id = aabb.new_group()
    enemy_timer()
end

function global.enemy_explode(pos, id)
    local explode = factory.create(global.factories.EXPLODE, pos)

    sprite.play_flipbook(explode, "enemy_impact", function()
        go.delete(explode)
        if id then
            go.delete(id)
        end
    end)
end

function global.pause_game()
    if global.isPaused == false then
        msg.post(global.proxy_url, "set_time_step", {factor = 0, mode = 1})
        global.isPaused = true
        aabb.run(false)
    else
        msg.post(global.proxy_url, "set_time_step", {factor = 1, mode = 1})
        global.isPaused = false
        aabb.run(true)
    end

end

function global.dispacth_collectable(pos)
    factory.create(global.factories.COLLECTABLE, pos, vmath.quat(0, 0, 0, 0))
end

return global
