low = -5.0
high = 5.1
high_wrap = 5.6
range = high - low
stages = 50
time = .5
time_min = .056
time_max = 30
time_range = time_max - time_min
time_mult = 1
dir = 1

function make_clockwise_spinner(stages)
    local spinner = {}

    for i=1,stages do
        local stage = to(high - (range*i/stages), dyn{t = time/stages})
        table.insert(spinner, stage)
    end

    table.insert(spinner, to(high_wrap, 0))
    table.insert(spinner, to(high, 0))

    return loop(spinner)
end

function make_counterclockwise_spinner(stages)
    local asl = {}

    for i=1,stages do
        local stage = to(low + (range*i/stages), dyn{t = time/stages})
        table.insert(asl, stage)
    end

    table.insert(asl, to(high_wrap, 0))
    table.insert(asl, to(low, 0))

    return loop(asl)
end

function make_clockwise_oneoff(stages, start, t)
    local spinner = {}
    local range = start - low

    for i=1,stages do
        local stage = to(start - (range*i/stages), dyn{t = (t*time_mult)/stages})
        table.insert(spinner, stage)
    end

    -- table.insert(asl, to(high_wrap, 0))
    -- table.insert(asl, to(high, 0))

    return spinner
end

local clockwise_spinner = make_clockwise_spinner(stages)
local counterclockwise_spinner = make_counterclockwise_spinner(stages)

output[1](clockwise_spinner)
-- output[1](counterclockwise_spinner)

local function truncate(num)
    return math.floor(num * 1000) / 1000
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

function process_t(t)
    t = truncate(t)
    if t ~= time then
        -- if t < .56 then
        --     return
        -- end
        -- print(t)

        output[1].dyn.t = t / stages

        time = t
    end
end

function update_t()
    output[1].dyn.t = (time * time_mult) / stages
end

-- p is 0-1
-- 0 is stopped, just above 0 is slowest rotation, 1 is fastest rotation
function update_time(p)
    local t = time_max-(p * time_range)
    -- t = truncate(t)
    if p == 0 then
        t = 0
    end

    if t ~= time then
        -- if t < .56 then
        --     return
        -- end
        -- print(t)

        if t > 0 then
            if time == 0 then
                -- need to start the spinner
                local c_v = output[1].volts
                time_mult = 1 - (c_v + high) / range

                output[1].action = make_clockwise_oneoff(stages, c_v, t)
                output[1]()
                -- output[1](make_clockwise_oneoff(stages, c_v))

                output[1].done = function()
                    time_mult = 1
                    output[1].done = function() end
                    output[1](clockwise_spinner)
                    update_t()
                end
            else
                output[1].dyn.t = (t * time_mult) / stages
            end
        elseif t < 0 then
            print("T LESS THAn ZERO???")
        else
            -- t == 0
            local c_v = output[1].volts
            output[1].done = function() end
            output[1]({to(c_v, 0)})
        end

        time = t
    end

end

input[1].mode( 'stream', 0.01 ) -- set input n to 'stream' every time seconds

input[1].stream = function(volts)
    -- local p = 1 - volts / 5
    local p = volts / 5
    p = truncate(p)
    p = clamp(p, 0, 1)
    -- p = p^3
    -- p = 1 - p
    p = biased_curve(p, 0.05, 2, 3)
    -- print(p)

    update_time(p)

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
