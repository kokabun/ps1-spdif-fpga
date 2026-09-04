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
def decode(path, div):
    samples=path.read_text().splitlines()
    assert set(samples)<=set('01'), 'X/Z on output'
    half=[int(x) for x in samples[::div]]
    pre={'Z':[1,1,1,0,1,0,0,0],'X':[1,1,1,0,0,0,1,0],'Y':[1,1,1,0,0,1,0,0]}
    start=next(i for i in range(len(half)-8) if half[i:i+8] in [pre['Z'],[1-x for x in pre['Z']]])
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
with tempfile.TemporaryDirectory(prefix='direct-spdif-test-') as p:
    tmp=Path(p)
    run('fifo_tb',tmp)
    for neg,left,slot in itertools.product((0,1),(0,1),(16,32)):
        run('integration_tb',tmp,[('NEG',neg),('LEFT',left),('SLOT',slot)])
        decode(tmp/'trace.txt',3)
print('PASS all 8 direct 384Fs configurations and FIFO tests')
