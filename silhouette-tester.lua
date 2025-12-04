lo = -4.7
hi = 5.05
lo_center = -5.0
hi_center = 5.6
val_mult = 1
-- lo_center = -5
-- hi_center = 5
t = 0.5
out = 1
stages = 50

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

-- circle = loop{
--     -- to(dyn{lo = -5}, 0),
--     -- to(dyn{hi = 5}, dyn{t = 0.5}),
--     -- to(lo, 0)
--     -- to(lo_center, 0),
--     -- to(hi_center, dyn{t = 0.5})
--     to(lo_center, dyn{t = t}),
--     to(hi_center, 0),
--     to(5.1, 0),
-- }

-- circle = loop({
--     to(3, dyn{t = t/5}),
--     to(1, dyn{t = t/5}),
--     to(-1, dyn{t = t/5}),
--     to(-3, dyn{t = t/5}),
--     to(-5, dyn{t = t/5}),
--     to(hi_center, 0),
--     to(5.1, 0),
-- })

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
    print("hi: "..hi..", lo: "..lo..", t: "..t)
end

function r()
    -- output[1](circle)
    output[1](rise)
    output[1].volts = lo
end

function h()
    output[1](rise)
end

function l()
    output[1].volts = lo
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
                -- hi = hi_center + val
            end
            -- output[out].dyn.hi = hi
        end,
        [2] = function(val)
            -- print("param 2: "..val)
            if control == "knob" then
                val = val / 9
                val = val - 0.5
                val = val * val_mult
                -- lo = lo_center + val
            end
            -- output[out].dyn.lo = lo
        end,
        [3] = function(val)
            val = (val / 9) * (val / 9)
            t = val + 0.01
            output[out].dyn.t = t / stages
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

output[out](make_circle(stages))
-- output[out](circle)

-- function parameterUpdater()
--     local n = 1
--     while true do
--         clock.sleep(.01)

--         handlers.param[n](txiVals.param[n])
--         handlers.cv[n](txiVals.cv[n])

--         n = (n % 4) + 1
--     end
-- end

