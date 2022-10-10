local g = require("scripts.global")

local ship = {}

local acceleration = 80
local deceleration = 100
local max_speed = 120
local rotation_speed = 180

local input = vmath.vector3()
local speed = 0
local missile_move_amount = g.vector_up * 400
local missile_factory = msg.url("main:/factories#ship_projectile")
local rot_amount
local move_amount

local function delete_projectile(self, url, property)
    go.delete(url)
end
local function fire_projectile()
    local missile = factory.create(missile_factory, g.spaceship.pos, g.spaceship.rot)
    local target = g.spaceship.pos + vmath.rotate(g.spaceship.rot, missile_move_amount)

    go.animate(missile, "position", go.PLAYBACK_ONCE_FORWARD, target, go.EASING_LINEAR, 6, 0, delete_projectile)
end

function ship.init()
    g.spaceship.url = msg.url("/spaceship")
    g.spaceship.sprite = msg.url("/spaceship#ship")

    g.spaceship.pos.x = g.screen_width / 2
    g.spaceship.pos.y = g.screen_height / 2
    g.spaceship.pos.z = 0

    g.spaceship.rot = go.get_rotation(g.spaceship.url)

    go.set_position(vmath.vector3(g.spaceship.pos.x, g.spaceship.pos.y, g.spaceship.pos.z), g.spaceship.url)
    go.set(g.spaceship.sprite, "cursor", 0.5)

    input = vmath.vector3()
    speed = 0
    timer.delay(0.15, true, fire_projectile)
end

function ship.input(action_id, action)

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

function ship.update(dt)

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

    input = vmath.vector3()

end

return ship
