low = -5.0
high = 5.1
high_wrap = 5.6
range = high - low
stages = 50
time = .5
time_min = .056
time_max = 30
time_range = time_max - time_min
dir = 1

function make_circle(stages)
    local asl = {}

    for i=1,stages do
        local stage = to(5 - (10*i/stages), dyn{t = time/stages})
        table.insert(asl, stage)
    end

    table.insert(asl, to(hi_center, 0))
    table.insert(asl, to(5.1, 0))

    return loop(asl)
end

output[1](make_circle(stages))

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

-- p is 0-1
-- 0 is stopped, just above 0 is slowest rotation, 1 is fastest rotation
-- function update_time(p)

input[1].mode( 'stream', 0.01 ) -- set input n to 'stream' every time seconds

input[1].stream = function(volts)
    -- local p = 1 - volts / 5
    local p = volts / 5
    p = clamp(p, 0, 1)
    -- p = p^3
    -- p = 1 - p
    p = biased_curve(p, 0.05, 2, 3)
    -- print(p)

    local t = time_max-(p * time_range)
    process_t(t)
end

-- maybe not great for cv
function biased_curve(p, center, lower_exponent, upper_exponent)
    if p < center then
        return center * ((p / center) ^ lower_exponent)
    else
        return 1 - (1 - center) * (((1 - p) / (1 - center)) ^ upper_exponent)
    end
end
