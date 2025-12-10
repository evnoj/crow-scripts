low = -5.0
high = 5.1
range = high - low
time_min = .045
time_max = 30
time_range = time_max - time_min
step_size = 0.01
steps = math.floor((range) / step_size) - 1
sync = true
sync_div = 1/1
sync_offset = 0
sync_step = 0
syncer_id = -1
-- sync_error_adjuster = 1 -- when synced, time gets multiplied by this
beat_sec = clock.get_beat_sec()
tempo = clock.tempo

-- MATH UTILS
local function truncate(num)
    return math.floor(num * 1000) / 1000
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

function await_clock()
    input[2].mode( 'change', 3, 0.1, 'rising' )
    input[2].change = function()
        input[2].mode( 'clock', 1/4)
        sync = true
        synced_rotation()
        syncer_id = clock.run(syncer)
        clock_timeout_checker:start()
    end
end

clock_timeout_checker = metro.init{
    event = function()
        if clock.get_last_input_time() > 4 then -- 4 second timeout
            clock_timeout:stop()
            free_rotation()
            await_clock()
        end
    end,
    time  = 1.0,
    count = -1
}

clock.handlers.tempo_change = function(new_tempo)
    beat_sec = clock.get_beat_sec()

    -- if math.abs(new_tempo - tempo) > .3 then -- ignore spurious tempo changes
    if math.abs(1 - (new_tempo / tempo)) > .01 then -- ignore spurious tempo changes
        print("CLOCK CHANGE: "..tempo.." -> "..new_tempo)
        update_offset()
    end

    tempo = new_tempo
end

output[4]({
    to(5, 0),
    to(5, 0.05),
    to(0, 0)
})

function syncer()
    while true do
        clock.sync(sync_div, sync_offset)
        output[4]()

        -- adjust oscillator time to account for error
        -- if dir == 1 then -- voltage is falling
           local step_error = sync_step - output[1].dyn.step
           local speed_error = step_error / steps * -1 * output[1].dyn.dir
           -- error greater than this is likely incorrect
           -- speed_error = clamp(speed_error, -.2, .2)
           local sync_error_adjuster = 1 + speed_error
           output[1].dyn.sync_error_adjuster = sync_error_adjuster
           -- print(sync_error_adjuster)
        -- else
        -- end
    end
end

function update_offset()
    print('UPDATING OFFSET')
    clock.cancel(syncer_id)
    syncer_id = clock.run(syncer)

    local current_beat = clock.get_beats()
    sync_offset = current_beat % sync_div
    sync_step = output[1].dyn.step
end

function update_sync_div(div)
    sync_div = div
    update_offset()
end

function free_rotation()
    -- output[1](spinner)
    output[1].dyn.sync_stepper = 0
    output[1].dyn.sync_step = steps
end

function synced_rotation()
    output[1].dyn.run = 0
    output[1].dyn.step = 0
    output[1].dyn.t = beat_sec * sync_div
    output[1].dyn.run = 1
    -- output[1].dyn.sync_step = steps
    -- output[1].dyn.sync_stepper = -1
    -- output[1]()

    update_offset()
    -- syncer_id = clock.run(syncer)
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

function update_time_synced(p, dir, run)
    -- output[1].dyn.t = (beat_sec * sync_div) * sync_error_adjuster
    output[1].dyn.t = (beat_sec * sync_div)
end

spinner = loop{
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

-- spinner = loop{
--     asl._while(dyn{step = steps+1}:step(dyn{dir = -1}):wrap(0, steps+1), {
--         asl._if((dyn{run=0} * dyn{sync_step=steps}:step(dyn{sync_stepper=0})), {
--             to(low + (dyn{step = steps+1} * step_size), (dyn{t = 0.5} / steps))
--         }),
--         asl._if((1 - (dyn{run=0} * dyn{sync_step=steps})), {
--             to(low + (dyn{step = steps+1}:step(dyn{dir = -1} * -1) * step_size), 0.001)
--         })
--     }),
--     -- falling
--     asl._if(1 - dyn{dir = -1}, {
--         to(low, 0),
--         to(high, 0),
--     }),
--     -- rising
--     asl._if(dyn{dir = -1}, {
--         to(high, 0),
--         to(low, 0),
--     }),
-- }

-- output[1](spinner)

input[1].mode( 'stream', 0.01 )
input[1].stream = function(volts)
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
        p = biased_curve(p, 0.05, 2, 3)

        update_time_free(p, dir, run)
    else
        update_time_synced(p, dir, run)
    end
end

-- maybe not great for cv
function biased_curve(p, center, lower_exponent, upper_exponent)
    if p < center then
        return center * ((p / center) ^ lower_exponent)
    else
        return 1 - (1 - center) * (((1 - p) / (1 - center)) ^ upper_exponent)
    end
end

function init()
    output[1].action = spinner
    output[1]()

    -- free_rotation()
    -- await_clock()
    synced_rotation()
    input[2].mode( 'clock', 1/2)
end
