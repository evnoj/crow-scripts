-- -- a function that works like "output.volts"
-- function start()
--     output[1].volts = -5
--     output[1](
--         to(5, dyn{slew=5})
--     )
-- end

-- function update_slew()
--     output[1].dyn.slew = 0.1
-- end

-- clock.run()

-- this value is a "time" not a "rate", hence the name
function env()
    output[1]({
        to(-5, 0),
        to(5, dyn{time=10})
    })

    clock.run(function()
        clock.sleep(5)
        print("setting output[1].dyn.time=1")
        output[1].dyn.time=1
    end)
end

-- function set_time(volts)
--   local time = volts
--   output[1].dyn.time = time
-- end

-- function init()
--   input[1].mode("change", 1.0, 0.1, 'rising')
--   input[2].mode("stream")

--   input[1].change = env
--   input[2].stream = set_time
-- end
