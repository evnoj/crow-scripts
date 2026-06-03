function await_clock()
    input[2].mode( 'change', 3, 0.1, 'rising' )
    input[2].change = function()
        input[2].mode( 'clock', 1/4)
        print('clocked')
        clock_timeout:start()
    end
end

clock_timeout = metro.init{
    event = function()
        if clock.time_since_last_input() > 4 then -- 4 second timeout
            clock_timeout:stop()
            await_clock()
            unclocked()
        end
    end,
    time  = 1.0,
    count = -1
}

function unclocked()
    print('unclocked')
end

-- requires my custom firmware
clock.handlers.tempo_change = function(tempo)
    print("tempo changed to "..tempo)
end

await_clock()
