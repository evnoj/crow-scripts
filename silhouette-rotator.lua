-- CONFIGURATION VARIABLES
clock_in_div = 1/4
low = -5.0
high = 5.1
-- min and max time for a cycle (a.k.a. spin speed, min time is max speed)
-- the parameter scaling for time is tuned for these values
-- likely will want to change time_parameter_handler if you change these
time_min = .045 -- speeds faster than this will start clicking
time_max = 30

-- CONVENIENCE VARIABLES
range = high - low
time_range = time_max - time_min
step_size = 0.01
steps = math.floor((range) / step_size) - 1
steps_half = math.floor(steps/2)
tempo = clock.tempo
beat_sec = clock.get_beat_sec()

-- STATE VARIABLES
sync = false
sync_div = 1/1
syncer_offset = 0
sync_step = 0
syncer_id = -1

-- UTILITIES
local function truncate(num)
    return math.floor(num * 1000) / 1000
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

local function biased_curve(p, center, lower_exponent, upper_exponent)
    if p < center then
        return center * ((p / center) ^ lower_exponent)
    else
        return 1 - (1 - center) * (((1 - p) / (1 - center)) ^ upper_exponent)
    end
end

-- CLOCKWORKS
function await_clock()
    input[2].mode( 'change', 3, 0.1, 'rising' )
    input[2].change = function()
        input[2].mode( 'clock', clock_in_div)
        sync = true
        spin_synced()
        clock_timeout_checker:start()
    end
end

clock_timeout_checker = metro.init{
    event = function()
        if clock.time_since_last_input() > 4 then -- 4 second timeout
            clock_timeout_checker:stop()
            spin_free()
            await_clock()
        end
    end,
    time  = 1.0,
    count = -1
}

clock.handlers.tempo_change = function(new_tempo)
    beat_sec = clock.get_beat_sec()

    if math.abs(1 - (new_tempo / tempo)) > .01 then -- ignore spurious tempo changes
        print("CLOCK CHANGE: "..tempo.." -> "..new_tempo)
        -- update_offset()
    end

    tempo = new_tempo
end

-- output[4]({
--     to(5, 0),
--     to(5, 0.05),
--     to(0, 0)
-- })

function syncer()
    local n = 0
    local step_error

    -- print("DIV: "..sync_div)

    while true do
        clock.sync(syncer_div, syncer_offset)
        local step = output[1].dyn.step
        -- print('hey')
        -- output[4]()

        -- local target_step = (sync_step + steps * 1/syncer_loop) % steps
        local target_step = sync_steps[n + 1]
        n = (n + 1) % syncer_num_subdiv

        -- adjust oscillator time to account for error
        step_error = target_step - step
        if math.abs(step_error) > steps_half then
            if step_error > 0 then
                step_error = steps - step_error
            else
                step_error = steps + step_error
            end
        end

        -- print("target step: "..target_step..", step: "..step.."step error: "..step_error)
        -- local speed_error = step_error / steps * -1 * output[1].dyn.dir
        local speed_error = step_error / (steps / syncer_num_subdiv) * -1 * output[1].dyn.dir

        -- error greater than this is likely incorrect
        -- TODO this caused problems, maybe a timer that implements it after
        -- the rotation stabilizes?
        -- speed_error = clamp(speed_error, -.2, .2)

        local sync_error_adjuster = 1 + speed_error
        output[1].dyn.sync_error_adjuster = sync_error_adjuster
    end
end

-- function ticker()
--     tid = clock.run(function()
--         while true do
--             clock.sync(1)
--             print('TICK')
--         end
--     end)
-- end

function new_syncer()
    clock.cancel(syncer_id)
    -- print("NEW SYNCER")
    output[1].dyn.sync_error_adjuster = 1

    sync_step = output[1].dyn.step

    sync_steps = {}
    if sync_div > 3/2 then
        syncer_div = 1
        syncer_offset = clock.get_beats() % syncer_div
        syncer_num_subdiv = sync_div

        -- local step = sync_step + math.ceil(steps * 1/sync_div)
        local step
        local dir = output[1].dyn.dir
        for i=1,sync_div do
            step = (sync_step + math.ceil(steps * i/sync_div) * dir) % steps
            sync_steps[i] = step
        end
    else
        syncer_div = sync_div
        syncer_offset = clock.get_beats() % syncer_div
        syncer_num_subdiv = 1
        sync_steps[1] = sync_step
    end


    -- local current_beat = clock.get_beats()
    -- syncer_offset = current_beat % sync_div
    -- sync_step = output[1].dyn.step
    -- output[1].dyn.sync_error_adjuster = 1

    syncer_id = clock.run(syncer)
end

function spin_free()
    sync = false
    clock.cancel(syncer_id)
    syncer_id = -1

    input[1].mode( 'stream', 0.001 )
    output[1].dyn.sync_error_adjuster = 1
end

function spin_synced()
    sync = true
    input[1].mode( 'stream', 0.01 )

    if output[1].dyn.run == 1 then
        output[1].dyn.t = beat_sec * sync_div
        new_syncer()
    end
end

-- p is 0-1, maps to time range
-- dir is -1 for ccw, 1 for clockwise
-- run is 1 for running, 0 for stopped
function update_time_free(p, dir, run)
    local t = time_max-(p * time_range)
    output[1].dyn.t = t
    output[1].dyn.dir = dir
    output[1].dyn.run = run
end

div_table = {
    16/1, -- 0 - .25
    8/1, -- .25 - .50
    6/1, -- .50 - .75
    4/1, -- .75 - 1.00
    3/1, -- 1.00 - 1.25
    2/1, -- 1.25 - 1.50
    3/2, -- 1.50 - 1.75
    4/3, -- 1.75 - 2.00
    5/4, -- 2.00 - 2.25
    1/1, -- 2.25 - 2.50
    1/1, -- 2.50 - 2.75
    4/5, -- 2.75 - 3.00
    3/4, -- 3.00 - 3.25
    2/3, -- 3.25 - 3.50
    1/2, -- 3.50 - 3.75
    1/3, -- 3.75 - 4.00
    1/4, -- 4.00 - 4.25
    1/6, -- 4.25 - 4.50
    1/8, -- 4.50 - 4.75
    1/16, -- 4.75 - 5.00
}

function update_time_synced(p, dir, run)
    local idx = math.ceil(p * 20)
    local div = div_table[idx] -- 5/19 = 0.26315
    local running = output[1].dyn.run
    local current_dir = output[1].dyn.dir
    local syncer_dirty = false

    if run == 1 and running == 0 then
        -- starting
        output[1].dyn.run = 1
        syncer_dirty = true
    elseif run == 0 then
        if running == 1 then
            -- stopping
            clock.cancel(syncer_id)
            syncer_id = -1
            output[1].dyn.run = 0
        end

        return
    end

    if dir ~= current_dir then
        output[1].dyn.dir = dir
        syncer_dirty = true
    end

    if div ~= sync_div then
        output[1].dyn.t = (beat_sec * div)
        sync_div = div
        syncer_dirty = true
    end

    if syncer_dirty then
        new_syncer()
    end
end

function time_parameter_handler(volts)
    local p = volts / 5
    p = truncate(p)
    p = clamp(p, -1, 1)

    local dir = -1
    local run = 1
    if p <= -0.05 then
        dir = 1
        p = math.abs(p)
    elseif p < 0.05 then
        p = 0
        run = 0
    end

    if not sync then
        -- p = p^3
        p = biased_curve(p, 0.05, 2, 3) -- maybe not great for CV

        update_time_free(p, dir, run)
    else
        update_time_synced(p, dir, run)
    end
end

function init()
    local spinner = loop{
        asl._while(dyn{step = steps+1}:step(dyn{dir = -1}):wrap(0, steps+1), {
            asl._if((dyn{run=0}), {
                to(low + (dyn{step = steps+1} * step_size), ((dyn{t = 0.5} / steps) * dyn{sync_error_adjuster = 1}))
            }),
            asl._if((1 - (dyn{run=0})), {
                to(low + (dyn{step = steps+1}:step(dyn{dir = -1} * -1) * step_size), 0.001)
            })
        }),
        -- falling
        asl._if(1 - dyn{dir = -1}, {
            to(low, 0),
            to(high, 0),
        }),
        -- rising
        asl._if(dyn{dir = -1}, {
            to(high, 0),
            to(low, 0),
        }),
    }

    -- output[1].action = spinner
    -- output[1]()
    output[1](spinner)

    input[1].stream = time_parameter_handler

    spin_free()
    await_clock()
    -- synced_spin()
    -- input[2].mode( 'clock', 1/2)
end
