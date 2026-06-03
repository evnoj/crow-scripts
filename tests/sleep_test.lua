clock.run(function()
    while true do
        clock.sleep(0.5)
        output[2].volts = 5
        clock.sleep(0.01)
        output[2].volts = 0
    end
end)
