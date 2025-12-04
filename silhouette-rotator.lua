low = -5.0
high = 5.1
high_wrap = 5.6
range = high - low
stages = 50
time = .5
time_min = .056
time_max = 8
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

input[1].mode( 'stream', 0.001 ) -- set input n to 'stream' every time seconds

input[1].stream = function(volts)
    local p = 1 - volts / 5
    p = clamp(p, 0, 1)
    p = p^3
    p = 1 - p
    local t = time_max-(p * time_range)
    process_t(t)
end


