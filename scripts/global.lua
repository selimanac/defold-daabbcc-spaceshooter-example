local global = {}

global.screen_width = 240
global.screen_height = 160
global.spaceship = {url = msg.url(), sprite = msg.url(), thruster = msg.url(), pos = vmath.vector3(), rot = vmath.vector3()}

global.vector_up = vmath.vector3(0, 1, 0)

global.move = {LEFT = hash("move_left"), RIGHT = hash("move_right"), UP = hash("move_up"), DOWN = hash("move_down")}

global.enemy_group_id = -1
global.enemies = {}

global.missiles = {}

local factories = {ENEMY = msg.url("main:/factories#enemy"), EXPLODE = msg.url("main:/factories#explode")}

local enemy_timer = function()
    timer.delay(rnd.double_range(0.1, 0.3), false, global.dispatch_enemy)
end

local function remove_enemy(self, url, property)
    go.delete(url)
end

function global.dispatch_enemy()
    local p
    local endpos

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
    local enemy = factory.create(factories.ENEMY, p, vmath.quat_rotation_z(angle))
    go.animate(enemy, "position", go.PLAYBACK_ONCE_FORWARD, endpos, go.EASING_LINEAR, rnd.range(6, 20), 0, remove_enemy)

    enemy_timer()
end

function global.init()
    global.enemy_group_id = aabb.new_group()
    enemy_timer()
end

function global.enemy_explode(pos, id)
    local explode = factory.create(factories.EXPLODE, pos)

    sprite.play_flipbook(explode, "enemy_impact", function()
        go.delete(explode)
        go.delete(id)
    end)

end

return global
