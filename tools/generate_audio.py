"""Synthesize original short 16-bit PCM game sounds; no third-party audio needed."""
import math
import random
import wave
from pathlib import Path
OUT=Path('assets/audio')
OUT.mkdir(parents=True,exist_ok=True)
RATE=22050
rng=random.Random(23)
def write(name,signals):
    data=bytearray()
    for sample in signals:
        n=int(max(-1,min(1,sample))*28000)
        data.extend(n.to_bytes(2,'little',signed=True))
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(data))
def tone(duration,frequency,kind='sine'):
    samples=[]
    for i in range(int(duration*RATE)):
        t=i/RATE
        env=max(0,1-t/duration)**1.6
        f=frequency*(1-t/duration*.27)
        phase=2*math.pi*f*t
        noise=rng.uniform(-1,1)
        if kind=='sword':v=.65*noise+.30*math.sin(phase)
        elif kind=='guard':v=.42*math.sin(phase)+.35*math.sin(phase*2.7)+.12*noise
        else:v=.58*math.sin(phase)+.22*math.sin(phase*2)
        samples.append(v*env*.7)
    return samples
if __name__=='__main__':
    write('sword',tone(.22,390,'sword'))
    write('guard',tone(.26,550,'guard'))
    notes=[523.25,659.25,784,1046.5]
    write('victory',sum([tone(.18,f) for f in notes],[]))
    print('3 efeitos sonoros originais WAV exportados.')
