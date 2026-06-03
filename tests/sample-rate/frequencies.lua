function make_oscillator(freq)
    return loop{ to(-5,0)
               , to(5, 1/freq)
               }
end

output[1](make_oscillator(120))
output[2](make_oscillator(222))
output[3](make_oscillator(440))
output[4](make_oscillator(666))
