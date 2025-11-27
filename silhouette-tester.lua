lo = -4.7
hi = 5.05
lo_center = -5.008298
hi_center = 5.610094
val_mult = 0.5
-- lo_center = -5
-- hi_center = 5
t = 0.5
out = 1

circle = loop{
    -- to(dyn{lo = -5}, 0),
    -- to(dyn{hi = 5}, dyn{t = 0.5}),
    -- to(lo, 0)
    -- to(lo_center, 0),
    -- to(hi_center, dyn{t = 0.5})
    to(lo_center, dyn{t = 0.5}),
    to(hi_center, 0),
    -- to(5, 0)
}

-- circle = loop{
--     to(dyn{lo = -5}, 0),
--     to(5, dyn{t = 0.5}),
--     to(dyn{hi = 5}, 0),
--     -- to(lo, 0)
--     -- to(lo_center, 0),
--     -- to(hi_center, dyn{t = 0.5})
-- }

rise = {
    to(hi, 0.5),
}

fall = {
    to(lo, 0)
}

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
                hi = hi_center + val
            end
            -- output[out].dyn.hi = hi
        end,
        [2] = function(val)
            -- print("param 2: "..val)
            if control == "knob" then
                val = val / 9
                val = val - 0.5
                val = val * val_mult
                lo = lo_center + val
            end
            -- output[out].dyn.lo = lo
        end,
        [3] = function(val)
            val = val / 9
            t = val + 0.01
            output[out].dyn.t = t
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

output[out](circle)

-- function parameterUpdater()
--     local n = 1
--     while true do
--         clock.sleep(.01)

--         handlers.param[n](txiVals.param[n])
--         handlers.cv[n](txiVals.cv[n])

--         n = (n % 4) + 1
--     end
-- end

