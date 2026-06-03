-- compare the speed of polling between fetching all values with "all" cmd vs. one at a time
local start_time,end_time,counter
local n = 2000

function avg_time(start_time, end_time, count)
    return (end_time - start_time) / count
end

local coro_all,coro_individual

coro_all = coroutine.create(function()
    ii.txi.event = function(e, data)
        if counter < n then
            counter = counter + 1
            ii.txi.get('all')
        else
            end_time = time()
            coroutine.resume(coro_all)
        end
    end

    counter = 0
    start_time = time()
    ii.txi.get('all')
    coroutine.yield()
    print("avg ms for polling via all getter: "..avg_time(start_time, end_time, n))
    coroutine.resume(coro_individual)
end)

coro_individual = coroutine.create(function()
    local remaining = 0
    ii.txi.event = function(e, data)
        if remaining == 0 then
            if counter < n then
                remaining = 7 -- restart when final getter of 8 returns
                counter = counter + 1
                ii.txi.get('param', 1)
                ii.txi.get('param', 2)
                ii.txi.get('param', 3)
                ii.txi.get('param', 4)
                ii.txi.get('in', 1)
                ii.txi.get('in', 2)
                ii.txi.get('in', 3)
                ii.txi.get('in', 4)
            else
                end_time = time()
                coroutine.resume(coro_individual)
            end
        else
            remaining = remaining - 1
        end
    end

    counter = 0
    start_time = time()
    ii.txi.get('param', 1)
    coroutine.yield()
    print("avg ms for polling via individual getters: "..avg_time(start_time, end_time, n))
end)

-- launch
coroutine.resume(coro_all)
