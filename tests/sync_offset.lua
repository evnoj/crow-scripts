div = 1
offset = 0
clocks ={}

trig = {
    to(5, 0),
    to(5, 0.05),
    to(0, 0)
}

function start()
    -- clock.sync(1)
    clocks[1] = clock.run(function ()
        while true do
            clock.sync(div, offset)
            -- print("synced: "..clock.get_beats())
            output[2](trig)
        end
    end)

    clocks[2] = clock.run(function ()
        while true do
            clock.sync(div)
            output[3](trig)
        end
    end)

    -- clocks[3] = clock.run(function ()
    --     while true do
    --         print("sleeped: "..clock.get_beats())
    --         output[3](trig)
    --         clock.sleep(clock.get_beat_sec())
    --     end
    -- end)
end

function stop()
    for _,id in pairs(clocks) do
        clock.cancel(id)
    end
end

-- clock.run(start)
start()
