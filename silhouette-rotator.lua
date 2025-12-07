low = -5.0
high = 5.1
range = high - low
time_min = .045
time_max = 30
time_range = time_max - time_min
step_size = 0.01
steps = math.floor((range) / step_size) - 1

spinner = loop{
    asl._while(dyn{step_counter = steps+1}:step(dyn{dir = -1}):wrap(0, steps+1), {
        asl._if(dyn{run=1}, {
            to(low + (dyn{step_counter = steps+1} * step_size), (dyn{t = 0.5} / steps))
        }),
        asl._if((1 - dyn{run=1}), {
            to(low + (dyn{step_counter = steps+1}:step(dyn{dir = -1} * -1) * step_size), 0.001)
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

output[1](spinner)

local function truncate(num)
    return math.floor(num * 1000) / 1000
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

-- p is 0-1, maps to time range
-- dir is -1 for ccw, 1 for clockwise
-- run is 1 for running, 0 for stopped
function update_time(p, dir, run)
    local t = time_max-(p * time_range)
    output[1].dyn.t = t
    output[1].dyn.dir = dir
    output[1].dyn.run = run
end

input[1].mode( 'stream', 0.001 )
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

    -- p = p^3
    p = biased_curve(p, 0.05, 2, 3)
    update_time(p, dir, run)
end

-- maybe not great for cv
function biased_curve(p, center, lower_exponent, upper_exponent)
    if p < center then
        return center * ((p / center) ^ lower_exponent)
    else
        return 1 - (1 - center) * (((1 - p) / (1 - center)) ^ upper_exponent)
    end
end
