# PS1 Parallel I/O S/PDIF dongle design study

[日本語版 / Japanese](parallel-io-dongle.md) · [README](../README.en.md)

Reviewed: 2026-09-03. The Japanese document is authoritative if versions conflict.

**This is a design study, not installation instructions or proof of hardware operation.**
This documentation-only change does not alter the existing PU-20 PoC, RTL, PLL,
or pin constraints. The one-jumper design is untested. Stop before connecting
hardware if voltage, supply, or continuity remains uncertain.

## Evidence classification

Primary evidence below means the product creator's own statements, not a Sony
specification. Community pinouts must not be promoted to Sony primary evidence.

| Class | Finding | Evidence and limitation |
|---|---|---|
| Primary: creator description | TheRetroChannel uses Parallel I/O for optical/coaxial S/PDIF and adds two missing signals to two unused contacts with internal wires | [Product page][trc]; its text does not identify the 31/65 signal assignments. No official schematic was verified here |
| Primary: creator documentation | PSIO occupies Parallel I/O; TheRetroChannel also excludes PSIO-modified consoles | [PSIO guide][psio], [TheRetroChannel][trc] |
| Third-party analysis | PIO carries SYSCLK1, BCLK, LRCLK, SDIN, power and GND; stock pins 31/65 are reported NC | [PCSX-Redux][pio], [PSX-SPX][pinouts]; verify revision and modifications |
| Third-party implementation report | TheRetroChannel's added connections are reported as Pin 31=DOUT and Pin 65=MCLK | [Analysis article][analysis]; indexed excerpts were available, but full-page retrieval failed during this review. Neither an official schematic confirmation nor a reproduction by this project |
| Third-party pinout | CXD2925Q DATO is Pin 99 | [PSX-SPX][pinouts]; Sony schematic and actual PU-20 continuity checks remain open |
| Hypothesis | Use SYSCLK1 and only one internal DATO/DOUT→PIO Pin 31 jumper | Conditional proposal below; not implemented or hardware-tested |

Do not transfer another board's DAC pin numbers to PU-20. DOUT here denotes the
added serial PCM output, not PIO bus D0–D15 or SDIN.

## Proposed PIO allocation

Numbers refer to the **PS1 68-contact PIO**, not FPGA pins. Match the source's
viewing direction to the console, PCB and mating connector; views can be mirrored.

| PIO pin | Reported function | Proposed use |
|---|---|---|
| 31 | NC on stock hardware | Added DOUT from CXD2925Q Pin 99 DATO |
| 65 | NC on stock hardware | Reported added MCLK in the third-party analysis; unused in the one-jumper proposal |
| 32 | SYSCLK1 (SYSCK in PSX-SPX) | Reported 33.8688 MHz reference |
| 33 | BCLK | Candidate PCM receive clock |
| 66 | LRCLK (LRCK) | Candidate channel boundary |
| 67 | SDIN, audio into PS1 | Undriven in Phase 1/2; future input expansion |
| 17 / 51 | Supply labelled 3.3 V in one source, 3.5 V in another | Candidate dongle supply; voltage/current capability unverified |
| 1 / 35, 34 / 68, etc. | GND | Candidate power returns; check continuity and current paths |

See [PCSX-Redux][pio] and [PSX-SPX][pinouts]. Similar names do not establish
that PIO BCLK/LRCLK and SPU BCKO/LRCO share a net or phase. The PIO audio
interface is also described as an external input; compatibility with added
DATO is a central validation requirement.

## One-jumper hypothesis and clock handling

```text
Inside PU-20: CXD2925Q Pin 99 DATO -- one proposed jumper --> PIO Pin 31

PIO -- verified levels / necessary protection and conversion --> FPGA
  Pin 31 DOUT --------------------------------------------> PCM RX
  Pin 33 BCLK / Pin 66 LRCLK ------------------------------> PCM RX
  Pin 32 SYSCLK1 -----------------------------------------> clock handling
                                               FIFO -> S/PDIF -> PLT133/T10W
  Pin 65: no added MCLK in this proposal
```

If 33.8688 MHz is precisely synchronous with 44.1 kHz audio, it equals 768Fs:

- `33.8688 MHz / 6 = 5.6448 MHz = 128Fs`: proposed BMC half-bit update rate.
- Alternatively, divide by two to obtain `16.9344 MHz = 384Fs` for the existing core.

These are arithmetic relationships, not evidence of hardware phase, synchronism,
or jitter. SYSCLK1 must not be equated with WCKO/MCLK.
Existing [spdif_tx.v](../rtl/spdif_tx.v) divides its 384Fs input by three;
feeding it 33.8688 MHz unchanged doubles the output rate. Phase 2 needs a
divider-ratio change or a suitable platform clock circuit and constraints.
Neither is implemented here. Check Gowin clock resources and timing analysis;
an ordinary logic divider is not automatically a suitable clock distribution solution.

Validate a stable SYSCLK1/Fs ratio, correct DATO reception with PIO clocks, and
sustained operation without FIFO overflow/underflow. A FIFO cannot correct
persistent frequency mismatch between independent clocks.

## Power, protection and hardware checks

**Neither a fixed 3.3 V rail nor direct powering of a Nano 9K/dedicated PCB is
established.** Resolve the 3.3/3.5 V source discrepancy by measurement and the
specific board's supply specifications.

- Check unloaded/loaded voltage, ripple, startup variation, available supply
  current and connector ratings.
- Budget typical, maximum and inrush current for FPGA core/I/O rails,
  regulators, optical transmitter and any future receiver.
- Address backfeeding, simultaneous USB power, signals entering unpowered I/O,
  power sequencing and protection.
- Measure logic levels, overshoot, loading and wiring effects; determine buffer
  needs. Supply voltage is not proof of I/O tolerance.
- With power off, verify that 31/65 are unused and inspect prior modifications.
  Do not assume hot-plugging is supported.
- Observe SYSCLK1, BCLK, LRCLK and DATO with an oscilloscope: frequency ratios,
  edges, setup/hold, RJ bit alignment and channel polarity. The development
  instrument is a DHO914S.
- Test startup, reset, silence, game audio and CD audio. Compare decoded output
  with known distinct left/right PCM; arithmetic alone is not validation.

Do not wire or power hardware while damaging voltage, driver contention or
supply conditions remain unresolved.

## Future SDIN / S/PDIF RX expansion

Pin 67 could support S/PDIF RX→PCM→PS1 audio input. [PCSX-Redux][pio] describes
PS1 as supplying BCLK/LRCLK while accepting SDIN. Do not assume its input
format matches the existing 16-bit RJ DATO receiver. External S/PDIF recovered
clock and PS1 clock may be asynchronous. Separately investigate supported
rates, clock-domain crossing, sample-rate conversion where necessary,
loss-of-signal muting, SPU external-input enable/volume settings and competing
drivers. No RX RTL is implemented.

## PSIO conflict

The [official PSIO guide][psio] establishes physical occupation of the same
port. [PSX-SPX][pinouts] also reports Switch Board reuse of 31/65 for /IRQ2
and /CS5. Removing the cartridge does not necessarily restore NC contacts.
Do not assume a passive splitter or pass-through provides coexistence;
exclude PSIO-modified consoles from this proposal's validation scope.

## Phases and acceptance criteria

| Phase | Scope | Gate before proceeding |
|---|---|---|
| 1 | Existing PU-20→Tang Nano 9K→PLT133/T10W PoC | Hardware confirmation of safe levels, PCM extraction, S/PDIF decoding and optical reception; current evidence is limited RTL tests |
| 2 | Added Pin 31 DOUT plus existing PIO clocks/audio signals | Verify power, SYSCLK1 synchronism, DATO/PIO clock alignment and sustained FIFO operation; leaving Pin 65 unchanged remains a hypothesis |
| 3 | Dedicated Parallel I/O PCB using GW1NZ-1 or similar | Incorporate Phase 2 results; finalize power, I/O ratings, clocking, resources, connector/enclosure and protection |

## Sources

- [TheRetroChannel product description][trc]: creator's topology and two-wire explanation, not an official schematic.
- [PSIO official Quick Start Guide][psio]: PIO connection.
- [PCSX-Redux PIO port][pio]: community analysis, not Sony specifications.
- [PSX-SPX pinouts][pinouts]: supply-label discrepancy, repurposed contacts and CXD2925Q pins.
- [Third-party analysis article][analysis]: reported 31=DOUT / 65=MCLK; full-page retrieval remained unavailable during this review.

[trc]: https://lectronz.com/products/playstation-ps1-digital-audio-adaptor
[psio]: https://ps-io.com/support/PSIO%20Quick%20Start%20-%2025C18%20R11.pdf
[pio]: https://github.com/grumpycoders/pcsx-redux/wiki/PIO-port
[pinouts]: https://psx-spx.consoledev.net/pinouts/
[analysis]: https://strefapsx.pl/forum/nasze-mody/cyfrowe-audio-z-ps1-moje-znaleziska/
