low = -5.0
-- low = -5.008298
high = 5.1
high_wrap = 5.6
-- high_wrap = 5.610094
range = high - low
sample_rate = 0.0001
step_size = range / 1000 * 4
out1_v = 0
rate = 1/100 / 3
dir = 1

-- staying within size limits is caller's responsibility
function make_queue(size)
    local t = {}

    for i=1,size do
        t[i] = {}
    end
    for i=1,size-1 do
        t[i].next = t[(i + 1)]
    end
    t[size].next = t[1]

    t.head = t[1]
    t.tail = t[1]
    t.empty = true

    function t:push(data)
        if self.empty then
            self.tail.data = data
            self.empty = false
        else
            self.tail = self.tail.next
            self.tail.data = data
        end
    end

    function t:pop()
        local data = self.head.data
        self.head.data = nil

        if self.head == self.tail then
            self.empty = true
        else
            self.head = self.head.next
        end

        return data
    end

    return t
end

out1_q = make_queue(50)
out1_q:push(0)
-- print("data: "..out1_q.tail.data)

down = lock{
    to(high_wrap, 0),
    to(low, 0),
    -- to(low+0.01, 0.01)
}

step = {
    to(dyn{next = 0}, dyn{rate = 1/100} )
}

output[1].done = function()
    -- print('done')
    if rate ~= 0 then
        -- output[1].dyn.rate = rate
        local rate = rate

        out1_v = out1_v + 0.2 * dir
        local asl
        if out1_v > high_wrap then
            out1_v = low + 0.2
            asl = {
                to(high_wrap, 0),
                to(low, 0),
                to(out1_v, rate)
            }
        elseif out1_v < low then
            out1_v = high_wrap - 0.2
            asl = {
                to(low, 0),
                to(out1_v, rate)
            }
        else
            asl = {
                to(out1_v, rate)
            }
        end
        -- output[1].dyn.next = out1_v

        output[1](asl)
    end
end
output[1](step)

-- function tick()
--     local tail = out1_q.tail.data
--     -- out1_q.tail.data = nil
--     local d = out1_q:pop()
--     -- print(d)
--     output[1].volts = d
--     -- output[1].volts = out1_q:pop()
--     -- print("data: "..tail)

--     if out1_q.empty then
--         local next = tail + step_size

--         if next > high_wrap then
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(high_wrap)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             -- out1_q:push(low)
--             output[1](down)
--             out1_q:push(low + next - high_wrap)
--             -- out1_q:push(-10.1 + next)
--         elseif next < low then
--             out1_q:push(low)
--             out1_q:push(high_wrap)
--             out1_q:push(high_wrap + next - low)
--             -- out1_q:push(10.1 + next)
--         else
--             out1_q:push(next)
--         end
--     end
-- end

-- ticker = metro.init{
--     event = tick,
--     time = sample_rate,
--     count = -1
-- }

-- ticker:start()
