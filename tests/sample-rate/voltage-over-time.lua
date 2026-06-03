results = {}
durations = {1, 10, 100} -- run tests over these durations

coro = coroutine.create(function()
    for _,duration in ipairs(durations) do
        results[duration] = {}
        local pending = 4

        for i=1,4 do
            output[i].action = {to(0,0), to(5,duration)}
            output[i].done = function()
                results[duration][i].time_done = time()
                pending = pending - 1
                if pending == 0 then
                    -- once all outputs have completed, start the next duration test
                    coroutine.resume(coro)
                end
            end

            results[duration][i] = {}
            results[duration][i].time_start = time()
            output[i]()
        end

        -- wait for ASL stages to complete before testing with the next duration
        coroutine.yield()
    end

    -- all tests done, print the results
    for duration,result in pairs(results) do
        print("\nresults for duration of "..duration.." seconds")
        print("---------")
        for i,t in ipairs(result) do
            local elapsed = (t.time_done - t.time_start) / 1000
            local error = string.format("%.2f%%", ((elapsed - duration) / duration) * 100)
            print("output "..i..":")
            print("  elapsed: "..elapsed)
            print("  error: "..error)
        end
    end
end)

coroutine.resume(coro)
