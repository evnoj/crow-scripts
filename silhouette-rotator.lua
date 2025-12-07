low = -5.0
high = 5.1
high_wrap = 5.6
range = high - low
time = .5
-- time = nil
direction = nil
time_min = .045
time_max = 30
time_range = time_max - time_min
step_size = 0.01
steps = math.floor((range) / step_size) - 1

-- clockwise_spinner = loop{
--     asl._while( dyn{loop_counter = steps+1}:step(-1):wrap(0, steps+1), {
--         to(low + (dyn{step_counter = steps}:step(-1):wrap(0, steps) * step_size), dyn{t=(0.5/steps)})
--     }),
--     to(low, 0),
--     to(high_wrap, 0),
--     to(high, 0)
-- }

function make_clockwise_oneoff(start, t)
    local range = start - low
    local steps_once = math.floor((range) / step_size) - 1

    -- print('making clockwise oneoff starting at '..start..' with t '..t)
    -- print('steps once is '..steps_once)

    local oneoff = {
        asl._while( dyn{loop_counter = steps_once+1}:step(-1), {
            to(low + (dyn{step_counter = steps_once}:step(-1) * step_size), dyn{t=(t/steps)})
        }),
        to(low, 0),
        to(high_wrap, 0),
        to(high, 0)
    }

    return oneoff
end

-- counterclockwise_spinner = loop{
--     asl._while( dyn{loop_counter = steps+1}:step(-1):wrap(0, steps+1), {
--         to(high - (dyn{step_counter = steps}:step(-1):wrap(0, steps) * step_size), dyn{t=(0.5/steps)})
--     }),
--     to(high, 0),
--     to(high_wrap, 0),
--     to(low, 0),
-- }

function make_counterclockwise_oneoff(start, t)
    local range = high - start
    local steps_once = math.floor((range) / step_size) - 1

    local oneoff = {
        asl._while( dyn{loop_counter = steps_once+1}:step(-1):wrap(0, steps+1), {
            to(high - (dyn{step_counter = steps_once}:step(-1) * step_size), dyn{t=(t/steps)})
        }),
        to(high, 0),
        to(high_wrap, 0),
        to(low, 0),
    }

    return oneoff
end

-- spinner = loop{
--     asl._if(dyn{run=1},
--         {to(dyn{pos=high}:step(dyn{dir = -1} * step_size):wrap(low, high), (dyn{t = time} / steps))}
--     ),
--     asl._if((1 - dyn{run=1}),
--         {to(dyn{pos=high}, 0.001)}
--     )
-- }

-- spinner = loop{
--     asl._if(dyn{run=1},
--         {to(low + (dyn{step_counter = steps}:step(dyn{dir = -1}):wrap(0, steps) * step_size), (dyn{t = time} / steps))}
--     ),
--     asl._if((1 - dyn{run=1}),
--         {to(dyn{pos=high}, 0.001)}
--     )
-- }

-- spinner = loop{
--     asl._if(dyn{run=1},
--         {
--             asl._while(dyn{step_counter = steps+1}:step(dyn{dir = -1}):wrap(0, steps+1), {
--                 to(low + (dyn{step_counter = steps+1} * step_size), (dyn{t = time} / steps))
--             }),
--             -- falling
--             asl._if(1 - dyn{dir = -1}, {
--                 to(low, 0),
--                 to(high, 0),
--             }),
--             -- rising
--             asl._if(dyn{dir = -1}, {
--                 to(high, 0),
--                 to(low, 0),
--             }),
--         }
--     ),
--     asl._if((1 - dyn{run=1}),
--         {to(dyn{pos=high}, 0.001)}
--     )
-- }

spinner = loop{
    asl._while(dyn{step_counter = steps+1}:step(dyn{dir = -1}):wrap(0, steps+1), {
        asl._if(dyn{run=1}, {
            to(low + (dyn{step_counter = steps+1} * step_size), (dyn{t = time} / steps))
        }),
        asl._if((1 - dyn{run=1}), {
            to(low + (dyn{step_counter = steps+1}:step(dyn{dir = -1} * -1) * step_size), (dyn{t = time} / steps))
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

function p()
    print("step_counter: "..output[1].dyn.step_counter)
    print("step follower: "..output[1].dyn.step_follower)
end

output[1](spinner)

-- output[1](clockwise_spinner)
-- output[1](counterclockwise_spinner)

local function truncate(num)
    return math.floor(num * 1000) / 1000
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

function update_t()
    output[1].dyn.t = time / steps
end

local function calculate_steps(range, step_size)
    return math.floor((range) / step_size) - 1
end

-- p is 0-1
-- dir is -1 for ccw, 0 for stopped, 1 for clockwise
function update_time(p, dir, run)
    local t = time_max-(p * time_range)
    output[1].dyn.t = t
    output[1].dyn.dir = dir
    output[1].dyn.run = run

    direction = dir
    time = t

    -- if dir == 0 then
    --     output[1].dyn.run = 0
    -- else
    --     output[1].dyn.run = 0
    -- end

    -- local time_changed = t ~= time
    -- local dir_changed = dir ~= direction

    -- if dir_changed then
    --     if dir == 1 then -- clockwise
    --         -- start clockwise spinner
    --         local c_v = output[1].volts

    --         -- output[1].action = clockwise_spinner
    --         -- local range = c_v - low
    --         -- local steps_once = calculate_steps(range, step_size)
    --         -- print(steps_once)
    --         -- output[1].dyn.loop_counter = steps_once + 1
    --         -- output[1].dyn.step_counter = steps_once
    --         -- output[1].dyn.t = t / steps
    --         -- output[1]()

    --         output[1].action = make_clockwise_oneoff(c_v, t)
    --         output[1]()
    --         output[1].done = function()
    --             output[1].done = function() end
    --             output[1](clockwise_spinner)
    --             update_t()
    --         end
    --     elseif dir == -1 then -- ccw
    --         -- start ccw spinner
    --         local c_v = output[1].volts

    --         -- output[1].action = counterclockwise_spinner
    --         -- local range = high - c_v
    --         -- local steps_once = calculate_steps(range, step_size)
    --         -- print(steps_once)
    --         -- output[1].dyn.loop_counter = steps_once + 1
    --         -- output[1].dyn.step_counter = steps_once
    --         -- output[1].dyn.t = t / steps
    --         -- output[1]()

    --         output[1].action = make_counterclockwise_oneoff(c_v, t)
    --         output[1]()
    --         output[1].done = function()
    --             output[1].done = function() end
    --             output[1](counterclockwise_spinner)
    --             update_t()
    --         end
    --     else
    --         -- stop spinner
    --         -- print('stopping')
    --         local c_v = output[1].volts
    --         output[1].done = function() end
    --         -- output[1]({to(c_v, 0)})
    --         output[1].volts = output[1].volts
    --     end

    --     direction = dir
    --     time = t
    -- elseif time_changed and direction ~= 0 then
    --     output[1].dyn.t = t / steps
    --     time = t
    -- end
end

input[1].mode( 'stream', 0.001 ) -- set input n to 'stream' every time seconds

input[1].stream = function(volts)
    -- local p = 1 - volts / 5
    local p = volts / 5
    p = truncate(p)
    p = clamp(p, -1, 1)

    local dir = -1
    local run = 1
    -- if p >= 0.05 then
    --     dir = 1
    -- elseif p <= -0.05 then
    --     dir = -1
    --     p = math.abs(p)
    -- else
    --     p = 0
    --     dir = 0
    -- end
    if p <= -0.05 then
        dir = 1
        p = math.abs(p)
    elseif p < 0.05 then
        p = 0
        run = 0
    end

    -- p = p^3
    -- p = 1 - p
    p = biased_curve(p, 0.05, 2, 3)
    -- print(p)

    update_time(p, dir, run)

    -- local t = time_max-(p * time_range)
    -- process_t(t)
end

-- maybe not great for cv
function biased_curve(p, center, lower_exponent, upper_exponent)
    if p < center then
        return center * ((p / center) ^ lower_exponent)
    else
        return 1 - (1 - center) * (((1 - p) / (1 - center)) ^ upper_exponent)
    end
end
