-- SILHOUETTE SPINNER: a clickless spinner for Silhouette's SPOT parameter
-- requires my firmware fork: https://github.com/evnoj/crow-ev
    -- "spinner" output mode
    -- telexi "all" command support
        -- also requires telexi fork: https://github.com/evnoj/telex-ev

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
spinner_out = 4 -- the crow output that the spinner uses
clock_in_div = 1/4 -- clock div for clock input
-- bottom and top of voltage range
bottom = -5.0
top = 5.0
-- min time in ms for a cycle, max time is 1024*min
time_min = 40

-- UTILITIES
-- truncates digits after thousandths place
local function truncate(num)
    return math.floor(num * 1000) / 1000
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

-- CLOCKWORK
function await_clock()
    input[2].mode( 'change', 3, 0.1, 'rising' )
    input[2].change = function()
        input[2].mode( 'clock', clock_in_div)
        output[spinner_out].clocked = true
        clock_timeout_checker:start()
    end
end

clock_timeout_checker = metro.init{
    event = function()
        if clock.time_since_last_input() > 4 then -- 4 second timeout
            clock_timeout_checker:stop()
            output[spinner_out].clocked = false
            await_clock()
        end
    end,
    time  = 1.0,
    count = -1
}

-- FUNCTIONALITY
-- p is 0-1
-- dir is -1 for ccw, 1 for clockwise, 0 for stopped
function update_time_free(p, dir)
    local t = time_min * 2^((1-p) * 10)
    output[spinner_out].time = t
    output[spinner_out].direction = dir
    -- print(t)
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
    output[spinner_out].direction = dir

    local idx = math.ceil(p * 20)
    div = div_table[idx]
    if div then
        output[spinner_out].spinner_clock_div = div
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

    if not output[spinner_out].clocked then
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

-- receives table where values 1-4 are params 1-4, 5-8 are ins 1-4
ii.txi.event = function(e, data)
    for i=1,8 do
        local handler = txi_poll_handlers[i]
        if handler then
            handler(data[i])
        end
    end
end

txi_poll_handlers = {
    -- param 1
    [1] = function(val)
        txi_vals.rate_offset = val + txi_vals.rate_offset_fine
    end,
    -- param 2
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
    -- param 3
    [3] = function(val)
        txi_vals.rate_attenuverter = val + txi_vals.rate_attenuverter_offset
    end,
    -- in 1
    [5] = function(val)
        if val > 2.5 then
            txi_vals.rate_multiplier = -1
        elseif val < -2.5 then
            txi_vals.rate_multiplier = 0
        else
            txi_vals.rate_multiplier = 1
        end
    end,
    -- in 3
    [7] = function(val)
        txi_vals.rate_attenuverter_offset = val
    end,
}

txi_metro = metro.init{
    time  = 0.002,
    count = -1,
    event = function()
        ii.txi.get('all')
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

        input[1].mode( 'stream', 0.001 )
        input[1].stream = time_parameter_handler

        output[spinner_out].mode = "spinner"
        output[spinner_out].bottom = bottom
        output[spinner_out].top = top

        await_clock()
    end)
end
