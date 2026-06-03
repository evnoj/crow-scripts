output[4].mode = "spinner"
output[4].direction = 1
output[4].clocked = true
output[4].spinner_clock_div = 1
s=output[4]
div=1
clock.tempo = 120
clock_source = "internal"

pulser = clock.run(function()
  while(true) do
    clock.sync(div)
    output[3].volts = 5
    clock.sleep(0.1)
    output[3].volts = 0
  end
end)

function t_clock()
  if clock_source == "internal" then
    input[1].mode( 'clock', 1)
  else
    input[1].mode( 'change' )
  end
end

