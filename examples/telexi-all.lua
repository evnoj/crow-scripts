-- when using txi.get('all'), receives table where values 1-4 are params 1-4, 5-8 are ins 1-4
ii.txi.event = function(e, data)
    for i=1,8 do
        local handler = txi_poll_handlers[i]
        if handler then
            handler(data[i])
        end
    end
end

txi_poll_handlers = {
    -- param 1
    [1] = function(val)
    end,
    -- param 2
    [2] = function(val)
        print(val)
    end,
    -- param 3
    [3] = function(val)
    end,
    -- in 1
    [5] = function(val)
    end,
    -- in 3
    [7] = function(val)
    end,
}

txi_metro = metro.init{
    time  = 0.2, -- can go to at least 0.002
    count = -1,
    event = function()
        ii.txi.get('all')
    end,
}

function init()
    ii.fastmode(true)

    -- delay on powerup to wait for txi to be initialized
    clock.run(function()
        clock.sleep(1)
        -- param 1
        ii.txi.param_bot(0, -5.01)
        ii.txi.param_top(0, 5.01)
        -- param 2
        ii.txi.param_bot(1, 1)
        ii.txi.param_top(1, 7)
        -- param 3
        ii.txi.param_bot(2, -1)
        ii.txi.param_top(2, 1)
        -- in 3
        ii.txi.in_bot(2, -1)
        ii.txi.in_top(2, 1)

        -- wait for txi param changes to take effect
        clock.sleep(0.1)
        txi_metro:start()

        -- do init stuff
    end)
end


