-- simple testing of wsyn, intended for interactive use in repl
-- example = 1 ; i2c note events
-- example = 2 ; CV pulse note events

example = 2
w = ii.wsyn -- less typing in repl, like w.lpg_time(0)

oct = 0
vel = 5
seq = sequins({ 0, 2, 4, 5, 7, 9, 11, 12 })
clock.tempo = 80 -- bpm of sequence

w.ar_mode(1)
w.curve(5)
w.ramp(0)
w.fm_index(0)
w.fm_env(0)
w.fm_ratio(1)
-- these settings reliably cause infinite sustain with i2c-triggered notes
-- lowering symmetry or raising time will stop infinite sustain
-- lowering time will make the symmetry cutoff for infinite sustain lower
w.lpg_symmetry(4.91)
w.lpg_time(-3.73)
-- w.lpg_time(-2)
w.patch(1, 7)

function note()
  local pitch = oct + (1 / 12 * seq())
  if example == 1 then
    w.play_voice(1, pitch,vel)
  else
    w.pitch(1, pitch)
    output[1](pulse(0.5, 8))
    -- output[1].volts = 8.0
  end
end

function run_seq()
  while true do
    note()
    clock.sync(1)
  end
end

id = nil
function start()
    id = clock.run(run_seq)
end

function stop()
    clock.cancel(id)
end

-- start()
w.pitch(1, 1)
w.pitch(2, 1)
w.pitch(3, 1)
w.pitch(4, 1)
-- output[1](pulse(10.1, 8))

