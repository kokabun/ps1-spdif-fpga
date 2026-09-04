# PS1 S/PDIF FPGA PoC

> Work sequence (2026-09-04): see [direct SPU first, PIO later](docs/direct-to-pio-plan.en.md). Validate the direct connection before moving to PIO. The plan also tracks porting the corrected integration RTL back into this PoC.

[日本語版 / Japanese](README.md)

Proof of concept for:

```text
SCPH-7000 / PU-20 (CXD2925Q)
        -> Tang Nano 9K (GW1NR-9)
        -> IEC 60958 / S/PDIF
        -> Akizuki 109598 (Everlight PLT133/T10W)
```

**Do not connect the PlayStation to the FPGA yet.** The CXD2925Q signal voltage,
sampling edge, LRCK polarity, slot length, and exact right-justified boundary
must first be measured on the actual PU-20. A wrong voltage can permanently
damage either board. This repository deliberately does not guess those facts.

## Current state

See the [Parallel I/O S/PDIF dongle design study](docs/parallel-io-dongle.en.md)
for future plans, with primary evidence, third-party reports, and untested
hypotheses separated. PIO support is not implemented.

- portable 16-bit right-justified PCM receiver
- portable 4-entry asynchronous FIFO
- IEC 60958 consumer stereo frame generator and BMC output
- exact clock-enable division from expected `384*Fs` WCKO to `128*Fs`
- Tang Nano 9K top, device selection, and pin constraints
- self-checking receiver and transmitter testbenches
- placeholder platform directories for GW1N-1 and GW1NZ-1

The 9K platform uses WCKO directly and therefore instantiates no PLL. If WCKO
is confirmed as 16.9344 MHz (`384 * 44.1 kHz`), a pulse every three WCKO cycles
is exactly the 5.6448 MHz BMC half-bit rate. `audio_clock.v` remains a separate
platform wrapper so a generated rPLL can replace it without changing the core.

## Design

```text
BCKO/LRCO/DATO -> right-justified RX --write--> async FIFO
                                                   |
WCKO -> platform audio_clock -> IEC 60958 + BMC <--read
                                      |
                                  PLT133/T10W
```

The receiver keeps the final 16 sampled bits of each LRCK slot. It exposes
`LRCK_LEFT` and `SAMPLE_ON_NEGEDGE` parameters; their current top-level values
are placeholders, not claims about CXD2925Q timing.

The transmitter emits 192 stereo frames per channel-status block, Z/X/Y
preambles, 16-bit audio in subframe bits 12..27, validity/user/channel-status,
even parity, and BMC. The consumer channel-status block is currently all zero;
that encodes consumer linear audio, no pre-emphasis, and the standard 44.1 kHz
frequency code. Professional/copyright/category/word-length refinements are
outside this PoC.

## PU-20 wiring candidates — measure before connecting

The working hypothesis from prior reverse-engineering references is:

| CXD2925Q candidate | Function | Tang Nano 9K PoC header | FPGA pin |
|---|---|---|---:|
| pin 100 `WCKO` | expected 16.9344 MHz / 384 Fs | J5-5 | 25 |
| pin 97 `BCKO` | serial bit clock | J5-6 | 26 |
| pin 98 `LRCO` | 44.1 kHz word/channel clock | J5-7 | 27 |
| pin 99 `DATO` | serial PCM | J5-8 | 28 |
| a verified digital ground | common reference | J5 GND | — |

These CXD2925Q pin numbers and timing assumptions are **candidates**, not fully
confirmed here from a Sony timing diagram. Verify IC orientation and continuity
on the exact PU-20 revision. Do not infer numbering from a board photograph.

The selected Nano 9K pins 25..29 are exposed on J5-5..J5-9 and are in 3.3 V I/O
banks in Sipeed's official schematic. This does **not** prove the PS1 signals are
3.3 V compatible.

### Oscilloscope checklist

These checks require an oscilloscope. The project developer uses a RIGOL
DHO914S, but another instrument with adequate bandwidth, channel count, and
measurement capabilities can be used. Probe the console signals before making
a galvanic connection to the Nano 9K:

1. Confirm ground reference and DC high/low voltages on WCKO, BCKO, LRCO, DATO.
2. Confirm LRCO is approximately 44.1 kHz and WCKO approximately 16.9344 MHz.
3. Measure BCKO frequency and count BCK cycles in each LRCO half/slot.
4. Decode a non-silent, asymmetric stereo test signal. Determine LRCO polarity,
   MSB/LSB order, the last 16-bit position, and whether data is stable on BCKO
   rising or falling edges.
5. Check setup/hold margin at the candidate FPGA sampling edge.
6. Only if levels meet the GW1NR 3.3 V bank limits, connect through short wires
   with a common ground. Otherwise design a proper level shifter/buffer first.
7. Recheck waveforms after connection for loading, ringing, and overshoot.
8. Confirm S/PDIF output is 5.6448 M transitions/second at the half-bit cadence,
   and check receiver lock and left/right channel identity.

After measurement, update the two parameters in `platform/tang_nano_9k/top.v`
and add measured clock periods to `tang_nano_9k.sdc`.

## PLT133/T10W (Akizuki 109598)

The manufacturer's Rev.5 datasheet specifies a 2.7–5.5 V recommended supply,
TTL-compatible input (`VIH >= 2.0 V`, `VIL <= 0.8 V`), 16 Mbps maximum rate,
and pin functions: 1=Vin, 2=Vcc, 3=GND, 4/5=NC.

For the PoC:

```text
Tang Nano J5-9 / FPGA pin 29 (spdif_out) -> PLT133 pin 1 Vin
Tang Nano 3V3                         -> PLT133 pin 2 Vcc
Tang Nano GND                         -> PLT133 pin 3 GND
0.1 uF ceramic directly between pins 2 and 3
PLT133 pins 4 and 5                    -> no connection
```

Power Vin and Vcc down together as required by the datasheet. Never feed 5 V
logic into a Nano 9K GPIO. The transmitter input must not float (the module can
turn its LED on when Vin floats).

Akizuki product page:
https://akizukidenshi.com/catalog/g/g109598/

Everlight datasheet:
https://www.everlighteurope.com/custom/files/datasheets/DPL-0000049.pdf

## Simulation

Install Icarus Verilog, then run:

```sh
make test
```

The RX test uses 32-bit slots containing distinct final 16-bit samples. The TX
test checks frame request cadence and BMC activity. Hardware-level timing and
optical interoperability still require the measurements above.

## Gowin EDA build and programming (Tang Nano 9K)

1. Open `platform/tang_nano_9k/ps1_spdif.gprj` in Gowin EDA.
2. Confirm device `GW1NR-LV9QN88PC6/I5` and top module `top`.
3. Enter the measured clock periods in `tang_nano_9k.sdc`.
4. Run **Synthesize**, then **Place & Route**. Do not accept unconstrained-clock
   warnings for a hardware test.
5. Connect the Nano 9K USB port and open Gowin Programmer.
6. Scan the JTAG chain, select the generated `.fs`, and use SRAM programming for
   the first reversible test. Use embedded/external flash only after validation.
7. Test the FPGA and optical module with a safe synthetic source before attaching
   the console.

Exact menu labels vary by Gowin EDA release; Sipeed's Nano 9K documentation and
Gowin Software User Guide cover driver/license setup.

## Known unknowns / stop conditions

- CXD2925Q output voltage and drive capability on this PU-20
- BCKO sampling edge and DATO setup/hold timing
- LRCO polarity and precise boundary behavior
- number of BCKO cycles per slot and whether padding exists before the sample
- WCKO frequency and phase continuity in all console audio states
- power sequencing between the powered console, Nano 9K, and optical module

Do not resolve any item by trial wiring. Stop, measure, and update RTL/constraints
from evidence. If the PS1 high level exceeds the Nano 9K bank rating or overshoot
crosses the absolute maximum, a level translator is mandatory.

## References and license

This original implementation is MIT licensed. The architecture was informed by
puhitaku/YOTSUHACK's working Tang Nano design. That repository is MIT at top
level, but its Ultra-Embedded S/PDIF RTL is GPL-2.0-or-later. None of that RTL is
copied here. See `THIRD_PARTY.md` for the exact provenance and official Sipeed
sources.
