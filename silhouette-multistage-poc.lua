lo_center = -5.0
hi_center = 5.6
val_mult = 1
time = 0.5
stages = 50
threshold = .57

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

function process_t(t)
    if t ~= time then
        if t == 0 then
            -- stop the spinner
            output[1].volts = output[1].volts
        elseif t < threshold and time >= threshold then
            -- change envelope to new number of stages
            -- how to make the envelope continuous based on current voltage?
            -- requires creating a one-off envelope that will then create a
            -- looping envelope when it finishes
            -- i know from testing this introduces a click
        elseif t >= threshold and time < threshold then
        else
            -- don't need to change number of stages
        end
        time = t
    end
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

handlers = {
    param = {
        [1] = function(val)
            -- print("param 1: "..val)
            -- val = val / 9
            -- val = val - 0.5
            -- val = val * val_mult
            -- hi = hi_center + val
            -- output[out].dyn.hi = hi
        end,
        [2] = function(val)
            -- print("param 2: "..val)
            -- val = val / 9
            -- val = val - 0.5
            -- val = val * val_mult
            -- -- lo = lo_center + val
            -- output[out].dyn.lo = lo
        end,
        [3] = function(val)
            val = (val / 9) * (val / 9)
            t = val + 0.01

            output[out].dyn.t = t / stages
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
