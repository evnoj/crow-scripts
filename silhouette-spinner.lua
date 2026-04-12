-- SILHOUETTE SPINNER: a clickless spinner for Silhouette's SPOT parameter
-- generates a rising or falling sawtooth wave to perform clickless "circular"
-- modulation of SPOT, similar to what the attenuverter does with no cable inserted
-- currently no "magnetic attractor" mechanism like the built-in spinner
    -- as of 2025/12/14, requires my crow firmware fork: https://github.com/evnoj/crow-ev
    -- some of my changes may be upstreamed and be available on mainline firmware later

-- crow output 1 is the spinner, plug into spot cv jack on silhouette
    -- on mine, this only works clickless if the attenuverter is fully ccw (negative)
    -- this means that the clockwise/counterclockwise are swapped for this script
-- crow input 1 is the speed, -5V-5V, negative is clockwise, positive ccw
    -- "0.5V/o" scaling - speed doubles/halves with 0.5v changes
-- (and then inverted by spot attenuverter to make positve clockwise and negative ccw)
-- txi knob 1 is a coarse offset for the speed
-- txi knob 2 is a fine offset for the speed
    -- noon is no offset, fully CW is double speed, fully CCW is half speed
-- txi knob 3 is an attenuverter for crow input 1
-- crow input 2 is for clock
-- txi cv 1: above 2.5V flips direction, less than -2.5V stops spinner
-- txi cv 3 adds to the knob 3 attenuverter (making it like an inverting VCA)
    -- -10v-10v, if txi knob 3 is at noon, then 5v is fully open, -5v is fully closed
-- idea for cv/knob: a slew or "brake" that causes speed changes to change smoothly

-- CONFIGURATION VARIABLES
clock_in_div = 1/4
low = -5.0
high = 5.1
-- min and max time for a cycle (a.k.a. spin speed, min time is max speed)
-- the parameter scaling for time is tuned for these values
-- likely will want to change time_parameter_handler if you change these
time_min = .027 -- speeds faster than this cause event queue full
time_max = 30
spinner_out = 4

-- CONVENIENCE VARIABLES
range = high - low
time_range = time_max - time_min
step_size = 0.01
steps = math.floor((range) / step_size) - 1
steps_half = math.floor(steps/2)
-- step_size_normalized = 2 / steps
tempo = clock.tempo
beat_sec = clock.get_beat_sec()

-- STATE VARIABLES
sync = false
sync_div = 1/1
syncer_offset = 0
sync_step = 0
syncer_id = -1

-- UTILITIES
-- truncates digits after thousandths place
local function truncate(num)
    return math.floor(num * 1000) / 1000
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

-- local function debug(s) print(s) end

local function biased_curve(p, center, lower_exponent, upper_exponent)
    if p < center then
        return center * ((p / center) ^ lower_exponent)
    else
        return 1 - (1 - center) * (((1 - p) / (1 - center)) ^ upper_exponent)
    end
end

-- CLOCKWORK
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

    if math.abs(1 - (new_tempo / tempo)) > .005 then -- ignore spurious tempo changes
--         debug("CLOCK CHANGE: "..tempo.." -> "..new_tempo)
        output[spinner_out].dyn.t = (beat_sec * sync_div)
        new_syncer()
        tempo = new_tempo
    end
end

-- for troubleshooting use
-- output[4]({
--     to(5, 0),
--     to(5, 0.05),
--     to(0, 0)
-- })

function syncer()
    local n = 0
    local step_error

    while true do
        clock.sync(syncer_div, syncer_offset)
        local step = output[spinner_out].dyn.step

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

        -- debug("target step: "..target_step..", step: "..step.." step error: "..step_error)
        local speed_error = step_error / (steps / syncer_num_subdiv) * -1 * output[spinner_out].dyn.dir

        -- ensure speed adjustment doesn't approach 0
        local sync_error_adjuster = math.max(1 + speed_error, 0.1)
        output[spinner_out].dyn.sync_error_adjuster = sync_error_adjuster
    end
end

function new_syncer()
    clock.cancel(syncer_id)

    sync_step = output[spinner_out].dyn.step
    syncer_div = sync_div
    syncer_num_subdiv = 1

    -- ensure a sync happens at least every second
    while syncer_div * beat_sec >= 1 do
        syncer_num_subdiv = syncer_num_subdiv + 1
        syncer_div = sync_div / syncer_num_subdiv
    end
    syncer_offset = clock.get_beats() % syncer_div

    local dir = output[spinner_out].dyn.dir
    sync_steps = {}
    for i=1,syncer_num_subdiv do
        step = (sync_step + math.ceil(steps * i/syncer_num_subdiv) * dir) % steps
        sync_steps[i] = step
    end

    output[spinner_out].dyn.sync_error_adjuster = 1
    syncer_id = clock.run(syncer)
end

-- FUNCTIONALITY
function spin_free()
    sync = false
    clock.cancel(syncer_id)
    syncer_id = -1

    input[1].mode( 'stream', 0.001 )
    output[spinner_out].dyn.sync_error_adjuster = 1
end

function spin_synced()
    sync = true
    input[1].mode( 'stream', 0.01 )

    if output[spinner_out].dyn.dir ~= 0 then
        output[spinner_out].dyn.t = beat_sec * sync_div
        new_syncer()
    end
end

-- p is 0-1, maps to time range
-- dir is -1 for ccw, 1 for clockwise, 0 for stopped
function update_time_free(p, dir)
    -- local t = time_max-(p * time_range)
    local t = time_min * 2^((1-p) * 10)
    ti=t
    pi=p
    -- if pr then
    --     print("t: "..t..", p: "..p)
    -- end
    output[spinner_out].dyn.t = t
    output[spinner_out].dyn.dir = dir
end
-- pr=true

div_table = {
    1/1,  -- placeholder
    16/1, -- 16.000,  0.25 - 0.50
    8/1,  --  8.000,  0.50 - 0.75
    6/1,  --  6.000,  0.75 - 1.00
    4/1,  --  4.000,  1.00 - 1.25
    3/1,  --  3.000,  1.25 - 1.50
    2/1,  --  2.000,  1.50 - 1.75
    3/2,  --  1.500,  1.75 - 2.00
    4/3,  --  1.333,  2.00 - 2.25
    5/4,  --  1.250,  2.25 - 2.50
    1/1,  --  1.000,  2.50 - 2.75
    4/5,  --  0.800,  2.75 - 3.00
    3/4,  --  0.750,  3.00 - 3.25
    2/3,  --  0.666,  3.25 - 3.50
    1/2,  --  0.500,  3.50 - 3.75
    1/3,  --  0.333,  3.75 - 4.00
    1/4,  --  0.250,  4.00 - 4.25
    1/6,  --  0.166,  4.25 - 4.50
    1/8,  --  0.125,  4.50 - 4.75
    1/16, --  0.062,  4.75 - 5.00
}

function update_time_synced(p, dir)
    local idx = math.ceil(p * 20)
    local div = div_table[idx] -- 5/19 = 0.26315
    local current_dir = output[spinner_out].dyn.dir
    local syncer_dirty = false

    if dir ~= current_dir then
        if dir == 0 then
            -- stopping
            clock.cancel(syncer_id)
            syncer_id = -1
            output[spinner_out].dyn.dir = 0

            return
        else
            output[spinner_out].dyn.dir = dir
            syncer_dirty = true
        end
    end

    if div and div ~= sync_div then
        output[spinner_out].dyn.t = (beat_sec * div)
        sync_div = div
        syncer_dirty = true
    end

    if syncer_dirty then
        new_syncer()
    end
end

function time_parameter_handler(volts)
    local p = txi_vals.rate_multiplier*(volts*txi_vals.rate_attenuverter + txi_vals.rate_offset) / 5
    p = truncate(p)
    p = clamp(p, -1, 1)

    local dir = -1
    -- center deadzone
    if p <= -0.05 then
        dir = 1
        p = math.abs(p)
    elseif p < 0.05 then
        p = 0
        dir = 0
    end

    if not sync then
        -- p = p^3
        -- p = biased_curve(p, 0.05, 2, 3) -- maybe not great for CV

        update_time_free(p, dir)
    else
        update_time_synced(p, dir)
    end
end

-- TXI CONTROL
txi_vals = {
    -- param = {},
    -- ['in'] = {}
}
-- for i=1,4 do
--     txi_vals.param[i] = 0
--     txi_vals.cv[i] = 0
-- end
txi_vals.rate_offset = 0
txi_vals.rate_offset_fine = 0
txi_vals.rate_attenuverter = 0
txi_vals.rate_attenuverter_offset = 0
txi_vals.rate_multiplier = 1

ii.txi.event = function(e, val)
    local handler = txi_handlers[e.name][e.arg]
    if handler then
        handler(val)
    end
end

txi_handlers = {
    param = {
        [1] = function(val)
            txi_vals.rate_offset = val + txi_vals.rate_offset_fine
        end,
        [2] = function(val)
            -- virtual noon notch
            if not (val <= -0.1 or val >= 0.1) then
                -- print('notcho')
                val = 0
            -- else
                -- print('no notcho')
            end
            txi_vals.rate_offset_fine = val
        end,
        [3] = function(val)
            txi_vals.rate_attenuverter = val + txi_vals.rate_attenuverter_offset
        end,
    },
    ['in'] = { -- in is a lua keyword
        [1] = function(val)
            if val > 2.5 then
                txi_vals.rate_multiplier = -1
            elseif val < -2.5 then
                txi_vals.rate_multiplier = 0
            else
                txi_vals.rate_multiplier = 1
            end
        end,
        [3] = function(val)
            txi_vals.rate_attenuverter_offset = val
        end,
    }
}

txi_metro = metro.init{
    time  = 0.002, -- 0.001 caused "event queue full" messages
    count = -1,
    event = function()
        ii.txi.get('param', 1)
        ii.txi.get('in', 1)
        ii.txi.get('param', 2)
        ii.txi.get('in', 2)
        ii.txi.get('param', 3)
    end,
}
txi_metro:start()

function init()
    ii.fastmode(true)

    -- delay on powerup to wait for txi to be initialized
    clock.run(function()
        clock.sleep(1)
        -- param 1: spinner speed/direction coarse, offset for crow input 1
        ii.txi.param_bot(0, -5.01) -- slight error needs to be compensated for
        ii.txi.param_top(0, 5.01)
        -- param 2: spinner speed/direction fine, added to param 1
        ii.txi.param_bot(1, -0.5)
        ii.txi.param_top(1, 0.5)
        -- param 3: attenuverter for crow input 1
        ii.txi.param_bot(2, -1)
        ii.txi.param_top(2, 1)
        -- in 3: added to param 3 for crow input 1, making it a VCA
        ii.txi.in_bot(2, -1)
        ii.txi.in_top(2, 1)

        -- wait for txi param changes to take effect
        clock.sleep(0.1)

        local spinner = loop{
            asl._while(dyn{step = steps+1}:step(dyn{dir = -1}):wrap(0, steps+1), {
                -- this caused event queue full at high speeds
                -- to(0.05 + 5.05 * (-1 + (dyn{step=steps+1} * step_size_normalized))^dyn{curve=1}, ((dyn{t = 0.5} / steps) * dyn{sync_error_adjuster = 1}))
                to(low + (dyn{step = steps+1} * step_size), ((dyn{t = 0.5} / steps) * dyn{sync_error_adjuster = 1}))
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

        output[spinner_out](spinner)

        input[1].stream = time_parameter_handler

        spin_free()
        await_clock()
    end)

    -- local spinner = loop{
    --     asl._while(dyn{step = steps+1}:step(dyn{dir = -1}):wrap(0, steps+1), {
    --         -- this caused event queue full at high speeds
    --         -- to(0.05 + 5.05 * (-1 + (dyn{step=steps+1} * step_size_normalized))^dyn{curve=1}, ((dyn{t = 0.5} / steps) * dyn{sync_error_adjuster = 1}))
    --         to(low + (dyn{step = steps+1} * step_size), ((dyn{t = 0.5} / steps) * dyn{sync_error_adjuster = 1}))
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

    -- output[spinner_out](spinner)

    -- input[1].stream = time_parameter_handler

    -- spin_free()
    -- await_clock()
end
