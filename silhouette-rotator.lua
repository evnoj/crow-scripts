low = -5.0
high = 5.1
high_wrap = 5.6
range = high - low
sample_rate = 0.001
step_size = range / 1000

-- max size of 4, enforced by caller
function make_queue()
    local t = {}
    t[1] = {}
    t[2] = {}
    t[3] = {}
    t[4] = {}
    t[1].next = t[2]
    t[2].next = t[3]
    t[3].next = t[4]
    t[4].next = t[1]

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

