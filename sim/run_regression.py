#!/usr/bin/env python3
"""Normalized-clock simulation; decode only emitted S/PDIF, not DUT internals."""
from pathlib import Path
import itertools, subprocess, tempfile
ROOT=Path(__file__).resolve().parents[1]
RTL=sorted((ROOT/'rtl').glob('*.v'))
def run(top, tmp, params=()):
    exe=tmp/'sim'
    subprocess.run(['iverilog','-g2012','-s',top,'-o',str(exe),*[f'-P{top}.{k}={v}' for k,v in params],str(ROOT/'sim'/f'{top}.v'),*map(str,RTL)],check=True)
    subprocess.run(['vvp',str(exe)],cwd=tmp,check=True,timeout=30)
def half_bits(samples, div):
    """Reset starts low; the first transition starts the first Z preamble.

    Check every recorded clock cycle before reducing to half-bit samples.
    Initial reset latency is arbitrary, but subsequent boundaries must retain
    the same phase. The final, possibly partial half-bit must also hold steady.
    """
    assert div > 0
    assert set(samples)<=set('01'), 'X/Z on output'
    assert samples and samples[0] == '0', 'trace must include reset-low output'
    first=next((i for i in range(1,len(samples)) if samples[i]!=samples[i-1]),None)
    assert first is not None, 'no output transitions'
    half=[]
    for at in range(first,len(samples),div):
        group=samples[at:at+div]
        assert all(x==group[0] for x in group), ('half-bit hold',at)
        if len(group)==div:
            half.append(int(group[0]))
    return half

def decode(path, div):
    half=half_bits(path.read_text().splitlines(),div)
    pre={'Z':[1,1,1,0,1,0,0,0],'X':[1,1,1,0,0,0,1,0],'Y':[1,1,1,0,0,1,0,0]}
    start=0
    frames=[]; valid_left=None; inverted=0; invalid=0
    for sf,at in enumerate(range(start,len(half)-63,64)):
        h=half[at:at+64];prev=half[at-1] if at else 0
        kind='Z' if sf%384==0 else 'Y' if sf%2 else 'X'
        assert h[:8]==[x^prev for x in pre[kind]], ('preamble',sf)
        inverted+=prev
        bits=[]
        for bit in range(28):
            a=8+bit*2
            assert h[a]!=h[a-1],('missing BMC boundary',sf,bit)
            bits.append(h[a]^h[a+1])
        assert sum(bits)%2==0,('parity',sf)
        word=sum(b<<(i+4) for i,b in enumerate(bits))
        assert word & 0xff0==0,('audio alignment',sf,hex(word))
        assert word & 0x60000000==0,('U/C',sf)
        value=(word>>12)&0xffff; v=(word>>28)&1
        if sf%2==0:valid_left=(value,v)
        else:
            left,lv=valid_left
            assert lv==v,('stereo validity',sf)
            if v:
                assert left==value==0, 'underflow must mute both channels'
                invalid+=1
            else:
                assert value-left==0x7000,('stereo pair',sf,left,value)
                frames.append(left-0x1000)
    assert len(frames)>=418,('missing audio',len(frames))
    assert frames==list(range(frames[0],420)),('loss/reorder',frames[:4],frames[-4:])
    assert invalid>0
    print(f'PASS external decode: {len(frames)} stereo frames, block wrap, PCM, parity, polarity, mute')
def check_corrupted_traces(path, div):
    samples=path.read_text().splitlines()
    first=next(i for i in range(1,len(samples)) if samples[i]!=samples[i-1])
    # Alter each of the formerly skipped positions within a stable half-bit.
    # Exercise decode itself, not just a separate test-only waveform checker.
    class Trace:
        def __init__(self, values): self.values=values
        def read_text(self): return '\n'.join(self.values)
    for offset in range(1,div):
        damaged=samples.copy()
        at=first+400*div+offset
        damaged[at]=str(1-int(damaged[at]))
        try:
            decode(Trace(damaged),div)
        except AssertionError as error:
            assert error.args[0][0]=='half-bit hold', error
        else:
            raise AssertionError('corrupted half-bit accepted')
    # Startup delay must not force a hard-coded trace sampling phase.
    reference=half_bits(samples,div)
    for delay in range(1,div):
        assert half_bits(['0']*delay+samples,div)==reference
    print('PASS waveform checker: rejects intra-half-bit glitches, tolerates reset latency')

def main():
    with tempfile.TemporaryDirectory(prefix='direct-spdif-test-') as p:
        tmp=Path(p)
        run('fifo_tb',tmp)
        for neg,left,slot in itertools.product((0,1),(0,1),(16,32)):
            run('integration_tb',tmp,[('NEG',neg),('LEFT',left),('SLOT',slot)])
            decode(tmp/'trace.txt',3)
            check_corrupted_traces(tmp/'trace.txt',3)
    print('PASS all 8 direct 384Fs configurations and FIFO tests')

if __name__=='__main__':
    main()
