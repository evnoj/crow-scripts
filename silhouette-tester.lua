lo = -5.0
hi = 5.1
-- lo_center = -5.0
lo_center = -5.008298
-- lo_center = -4.939958
-- hi_center = 5.6
hi_center = 5.610094
-- hi_center = 5.682232
val_mult = 1.5
-- t = 1
t = 0.05
out = 2
stages = 50
step_size = 0.01
steps = math.floor((hi - lo_center) / step_size) - 1

-- circle = loop{
--     -- to(dyn{lo = -5}, 0),
--     -- to(dyn{hi = 5}, dyn{t = 0.5}),
--     -- to(lo, 0)
--     -- to(lo_center, 0),
--     -- to(hi_center, dyn{t = 0.5})
--     to(lo_center, dyn{t = t*.96}),
--     -- to(lo_center, dyn{t = t}),
--     to(hi_center, 0),
--     to(5.1, 0),
-- }

circle = loop{
    -- to(dyn{lo = -5}, 0),
    -- to(dyn{hi = 5}, dyn{t = 0.5}),
    to(dyn{lo = -5}, dyn{t = 0.5}),
    to(dyn{hi = 5}, 0),
    -- to(lo, 0)
    -- to(lo_center, 0),
    -- to(hi_center, dyn{t = 0.5})
    -- to(lo_center, dyn{t = t}),
    -- to(hi_center, 0),
    -- to(5.1, 0),
}

-- circle = loop({
--     to(3, dyn{t = t/5}),
--     to(1, dyn{t = t/5}),
--     to(-1, dyn{t = t/5}),
--     to(-3, dyn{t = t/5}),
--     to(-5, dyn{t = t/5}),
--     to(hi_center, 0),
--     to(5.1, 0),
-- })

-- circle = loop{
--     to(dyn{pos=hi_center}:step(-0.1):wrap(lo_center, hi_center), dyn{t=(t/steps)})
--     -- to(lo_center, dyn{t = t}),
--     -- to(hi_center, 0),
--     -- to(5.1, 0)
-- }

-- circle = loop{
--     asl._while( dyn{counter = steps+1}:step(-1):wrap(0, steps+1), {
--         -- to(dyn{pos=hi}:step(-1 * step_size):wrap(lo, hi-step_size), dyn{t=(t/steps)})
--         to(dyn{pos=hi}:step(-0.02):wrap(lo, hi-step_size), dyn{t=(t/steps)})
--     }),
--     to(lo_center, 0),
--     to(hi_center, 0),
--     to(hi, 0)
-- }
-- circle = loop{
--     asl._while( dyn{loop_counter = steps+1}:step(-1):wrap(0, steps+1), {
--         to(lo + (dyn{step_counter = steps}:step(-1):wrap(0, steps) * step_size), dyn{t=(t/steps)})
--     }),
--     -- to(lo_center, 0),
--     to(hi_center, 0),
--     to(hi, 0)
-- }
output[out](circle)
-- output[2](circle)

local function round_decimal(n, place)
    return math.floor(place*n + 0.5)/place
end

local function round_thousandths(n)
    return math.floor(1000*n + 0.5)/1000
end

local function round_hundredths()
    output[1].dyn.pos = math.floor(100*output[1].dyn.pos + 0.5)/100
    -- return math.floor(100*n + 0.5)/100
end

local function round_pos()
    output[1].dyn.pos = round_decimal(output[1].dyn.pos, 100)
end

rounder = metro.init{ event = round_pos
                      , time  = 1
                      , count = -1 -- nb: -1 is 'forever'
                      }
-- rounder:start()

-- circle = loop{
--     times(5, {
--         to(lo_center, dyn{t = t}),
--         to(hi_center, 0),
--         to(5.1, 0)
--     }),
-- }

-- circle = loop{
--     asl._while( mutable(5+1):wrap(1,6)-1, {
--         to(lo_center, dyn{t = t}),
--         to(hi_center, 0),
--         to(5.1, 0),
--         -- -- Counter decrements automatically each iteration
--         -- to(0, 0)  -- dummy operation to trigger counter check
--     })
-- }

-- circle = loop{
--     asl._while( dyn{counter = 6}:step(-1):wrap(0, 6), {
--         to(lo_center, dyn{t = t}),
--         to(hi_center, 0),
--         to(5.1, 0)
--     }),
--     to(5, 5)
-- }

function make_circle(stages)
    local asl = {}

    for i=1,stages do
        local stage = to(5 - (10*i/stages), dyn{t = t/stages})
        table.insert(asl, stage)
    end

    table.insert(asl, to(hi_center, 0))
    table.insert(asl, to(5.1, 0))

    return loop(asl)
end

-- function make_circle()
--     return {
--         to(hi, 0),
--         to(5.1, 0),
--         to(lo, t),
--     }
-- end

-- output[1].done = function()
--     output[1](make_circle())
-- end

-- function make_fall()
--     return {
--         to(-2, t*.4),
--     }
-- end

-- function make_wrap()
--     return {
--         to(-5, t*.3),
--         to(5.6, 0),
--         to(5.1, 0),
--         to(2, t*.3)
--     }
-- end

-- function end_fall()
--     output[1].done = end_wrap
--     output[1](make_wrap())
-- end

-- output[1].done = end_fall

-- function end_wrap()
--     output[1].done = end_fall
--     output[1](make_fall())
-- end

-- circle = loop{
--     to(lo_center, 0),
--     to(5.1, dyn{t = 0.5}),
--     to(hi_center, 0),
--     -- to(lo, 0)
--     -- to(lo_center, 0),
--     -- to(hi_center, dyn{t = 0.5})
-- }

function p()
    print("high: "..output[out].dyn.hi..", low: "..output[out].dyn.lo)
    print("time: "..t)
end

txiVals = {
    param = {},
    cv = {}
}

for i=1,4 do
    txiVals.param[i] = 0
    txiVals.cv[i] = 0
end

ii.txi.event = function(e, val)
    if e.name == 'in' then -- don't use 'in' because its a lua keyword
        e.name = 'cv'
    end
    txiVals[e.name][e.arg] = val
end

control = "knob"

handlers = {
    param = {
        [1] = function(val)
            -- print("param 1: "..val)
            if control == "knob" then
                val = val / 9
                val = val - 0.5
                val = val * val_mult
                hi = hi_center + val
            end
            output[out].dyn.hi = hi
        end,
        [2] = function(val)
            -- print("param 2: "..val)
            if control == "knob" then
                val = val / 9
                val = val - 0.5
                val = val * val_mult
                lo = lo_center + val
            end
            output[out].dyn.lo = lo
        end,
        [3] = function(val)
            val = (val / 9) * (val / 9)
            t = round_thousandths(val + 0.01)
            output[out].dyn.t = t
            -- output[out].dyn.t = t / stages
            -- output[out].dyn.t = t / steps
            -- output[out].dyn.t = t * .96
            -- output[out].dyn.wrap_t = t * .02

            -- if t ~= old_t then
            --     local v = output[1].volts
            --     local p = v + 5 / 10.6
            --     local time = t * (1 - p)
            --     output[out]({
            --         to(lo_center, time),
            --         to(hi_center, 0),
            --         to(5.1, 0),
            --     })
            --     output[out].done = function()
            --         output[out].done = nil
            --         output[out](loop{
            --             to(lo_center, time),
            --             to(hi_center, 0),
            --             to(5.1, 0),
            --         })
            --     end
            --     -- output[out].dyn.t = t
            -- end

            -- old_t = t
        end,
        [4] = function(val)
        end
    },
    cv = {
        [1] = function(val)
        end,
        [2] = function(val)
        end,
        [3] = function(val)
        end,
        [4] = function(val)
        end
    }
}

clock.run(function()
    local n = 1
    while true do
        clock.sleep(0.01)
        ii.txi.get('param', n)

        handlers.param[n](txiVals.param[n])
        handlers.cv[n](txiVals.cv[n])

        n = (n % 4) + 1
    end
end)

-- output[out](make_circle(stages))

function parameterUpdater()
    local n = 1
    while true do
        clock.sleep(.01)

        handlers.param[n](txiVals.param[n])
        handlers.cv[n](txiVals.cv[n])

        n = (n % 4) + 1
    end
end

