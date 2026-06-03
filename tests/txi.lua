-- TXI CONTROL
txi_vals = {
    param = {},
    cv = {}
}

for i=1,2 do
    txi_vals.param[i] = 0
    txi_vals.cv[i] = 0
end

ii.txi.event = function(e, val)
    if e.name == 'in' then -- don't use 'in' because its a lua keyword
        e.name = 'cv'
    end
    -- txiVals[e.name][e.arg] = val

    local handler = txi_handlers[e.name][e.arg]
    if handler then
        handler(val)
    end
end

txi_handlers = {
    param = {
        -- these values are simply stored and handled in the main update loop
        -- driven by the input[1].stream handler
        [1] = function(val)
            -- local processed = val - 4.94
            if p then
                print(val)
            end
            -- txi_vals.param[1] = val / 16384
        end,
        -- [2] = nil,
    },
    cv = {
        [1] = function(val)
        end,
        [2] = function(val)
        end,
    }
}

txi_handlers.param[2] = txi_handlers.param[1]
txi_handlers.param[3] = txi_handlers.param[1]
txi_handlers.param[4] = txi_handlers.param[1]

-- clock.run(function()
--     local n = 1
--     while true do
--         clock.sleep(0.01)
--         ii.txi.get('param', n)
--         ii.txi.get('cv', n)

--         txi_handlers.param[n](txiVals.param[n])
--         txi_handlers.cv[n](txiVals.cv[n])

--         n = (n % 4) + 1
--     end
-- end)

-- ii.txi.param_bot(0, 0)
-- ii.txi.param_top(0, 5)
p = true

txi_metro = metro.init{
    time  = 0.1,
    count = -1,
    event = function()
        get(1)
        -- ii.txi.get('param', 1)
        -- ii.txi.get('in', 1)
        -- ii.txi.get('param', 2)
        -- ii.txi.get('in', 2)
    end,
}
-- txi_metro:start()

function get(n)
    ii.txi.get('param', n)
end
