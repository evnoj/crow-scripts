-- simple testing of wsyn, intended for interactive use in repl
-- note() plays one note
-- clear() sends note on then note off (0 velocity) to all voices
-- start() starts playing a steady sequence
-- stop() stops the sequence

w = ii.wsyn -- less typing in repl, like w.lpg_time(0)

oct = -1
vel = 5
seq = sequins{0,2,4,5,7,9,11,12}
clock.tempo = 80 -- bpm of sequence

w.ar_mode(1)
w.curve(5)
w.ramp(0)
w.fm_index(0)
w.fm_env(0)
w.fm_ratio(1)
-- these settings reliably cause infinite sustain
-- lowering symmetry or raising time will stop infinite sustain
-- lowering time will make the symmetry cutoff for infinite sustain lower
w.lpg_symmetry(4.91)
w.lpg_time(-2.73)


function note()
        local pitch = oct + (1 / 12 * seq())
        -- w.play_note(pitch, vel)
        w.play_voice(1, pitch, vel)
end

function clear()
    w.play_voice(1, 1, 1)
    w.play_voice(2, 1, 1)
    w.play_voice(3, 1, 1)
    w.play_voice(4, 1, 1)

    w.play_voice(1, 1, 0)
    w.play_voice(2, 1, 0)
    w.play_voice(3, 1, 0)
    w.play_voice(4, 1, 0)
end

function run_seq()
    while (true) do
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
