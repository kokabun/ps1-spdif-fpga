# Standalone 74LCX541FT input-board test — PS1 disconnected

[日本語・正本](input-buffer-test.md) / [README](../README.en.md) / [Input proposal](ps1-input-interface.en.md)

Created 2026-09-12; explanation and figure updated 2026-09-13. English translation; Japanese is authoritative. **Disconnect all PS1 and optical-transmitter wiring.** Check whether the breadboard-mounted 74LCX541FT (LCX541 below) correctly reproduces the input's logic 0 and 1 at its output.

Contents: [Test overview](#test-overview) / [Wiring](#wiring) / [Build](#build) / [Procedure](#procedure) / [Records and sources](#records-and-sources)

## Test overview

For PC capture and storage use the [step-by-step DHO914S CLI procedure](input-buffer-measurement.en.md). Originals, analyses and notes stay in this repository, separate from reviewed publication material. This document remains the circuit and assessment reference.

LCX541 is a buffer: it receives a signal and drives an output. When enabled, a Low input (near 0 V) produces a Low output, and a High input (near 3.3 V in this test) produces a High output. Keeping 0 and 1 the same is called **non-inverting** operation.

### Why use a buffer IC?

**Receive PS1's logic 0/1 and drive the FPGA with Nano-side 3.3 V logic.** FPGA inputs have voltage limits; negative excursions and signal slew on the current PS1 wiring remain unchecked. This PoC [evaluates a buffered interface](ps1-input-interface.en.md#proposal).

- **Match voltage levels:** Powered at 3.3 V, LCX541 accepts inputs up to 5.5 V within its specifications and drives 3.3 V logic. This does not establish that PS1 signals are 5 V.
- **Drive the FPGA side:** LCX541 drives downstream wiring and FPGA inputs. The PS1-to-buffer wiring and buffer input still load PS1.
- **Control the output:** `/OE` enables or disables outputs for programming and staged testing.

See [Toshiba's datasheet](https://toshiba.semicon-storage.com/info/74LCX541FT_datasheet_en_20181030.pdf?did=15179&prodName=74LCX541FT), §§2, 8, 10 and 11. The buffer also has input-voltage and slew limits. **Additional protection against negative excursions still needs evaluation.** Disabling `/OE` does not prevent input overvoltage.

This is the project's design choice, not a requirement for every PS1 modification. The FPGA performs the S/PDIF format conversion.

### What this test establishes first

Verify that the assembled buffer reproduces logic 0/1 and enables/disables its outputs. This standalone test with a 3.3 V source does not establish compatibility with actual PS1 voltages.

Use the Nano 9K as a source: FPGA29 → LCX541 A1 → Y1 → oscilloscope only. Supply the buffer from Nano 3V3/GND. Do not connect buffer outputs to FPGA input pins yet.

Use an oscilloscope to compare the buffer input and output; the instrument used here is a DHO914S.

| Step | What to do | Expected basic behavior |
|---|---|---|
| 1. Wiring and supply | Inspect wiring with power off, then measure supply voltage with a multimeter | About 3.3 V at the IC; no short or abnormal heating |
| 2. Fixed voltages (static test) | Apply 0 V and 3.3 V to the input in separate trials | Enabled output follows Low/High. When disabled, its resistor pulls it Low |
| 3. Repeating waveform (dynamic test) | Feed alternating 0/1 from Nano; measure input on CH2 and output on CH3 | Enabled output repeats at the same frequency with a small delay |

This table is an overview; follow the [procedure](#procedure) for actual connections and changes. Start with the default **approximately 2.7 MHz** (2.7 million cycles per second), one photo and frequency/voltage readings. Precise delay measurements and higher-frequency tests can wait.

This establishes assembly and basic operation. **Audio extraction and permission to connect PS1 require further checks**; protection circuitry is not yet finalized.

## Wiring

Power off and remove USB before assembly or rewiring. Check the IC's pin-1 mark, adapter's 0.65 mm side, pad continuity and adjacent-pin shorts. IC pin numbers below are not adapter hole numbers.

See the [solderless-breadboard layout in the authoritative Japanese document](ps1-input-interface.md#ブレッドボード構築イメージ) for placement and the boundary between wiring to install now and future wiring. Keep Nano off the breadboard and connect only its FPGA29→Rs→Rin test source plus 3V3/GND with jumpers.

![Standalone test wiring, Japanese labels](images/lcx541-standalone-test.svg)

Part references now match the [numbered breadboard guide](ps1-input-interface.en.md#construction-layout-illustration): U1=LCX541, R1=Rs, R2=Rin, R3=Rpd, R4=Rout, R5=Rhold, R6=enable pullup, C1=Cdec, C2=Cbulk, JP_EN1=SW_ENABLE. TP1/TP2 correspond to TP_A/TP_Y; TP3/TP4 are ground points. The revised placement uses **J17 for the output test point**, not the previous J3.

The Japanese diagram has three panels: signal path at the top, power at bottom left, and output enable/disable at bottom right. [Open the SVG to zoom](images/lcx541-standalone-test.svg). It is a connection diagram, not a physical placement template.

| Symbol | Meaning |
|---|---|
| `A1` / `Y1` | IC input/output. Parentheses give IC pin numbers, not adapter hole numbers |
| `TP_A` / `TP_Y` | Probe-tip test points: CH2 input, CH3 output. These are `TP_A1` / `TP_Y1` in the breadboard layout |
| `3V3`, `VCC` / `GND` | 3.3 V supply, IC supply pin / voltage reference (0 V). All GND labels share one connection |
| `/OE1`, `/OE2`, `SW_ENABLE` | Output-control pins and jumper. Removed disables; connected to GND enables. The IC remains powered |
| `Hi-Z` / `NC` | Hi-Z means the output drives neither High nor Low. NC means leave unconnected. Neither means a direct GND connection |

`Rs`, `Rin` and `Rout` are series signal resistors. `Rpd` and `Rhold` pull otherwise undriven nodes toward Low. `Cdec` and `Cbulk` reduce supply fluctuations. Use the values and placement in the following table.

| Connection | Pin / wiring |
|---|---|
| VCC | IC **20** → Nano `3V3` (official schematic J6-24), **never 5V** |
| GND | IC **10** → Nano `GND` (J6-23); all grounds common |
| `/OE1`, `/OE2` | IC **1, 19** tied together, 10 kΩ pullup to 3V3 and a removable jumper (or switch) to GND; initially open |
| A1 | Nano FPGA **29**, J5-9 → Rs 33 Ω near Nano → Rin 100 Ω near IC → IC **2** |
| TP_A | At A1; Rpd 100 kΩ from A1 to GND |
| Y1 | IC **18** → Rout 33 Ω near IC → TP_Y; Rhold 100 kΩ from TP_Y to GND; **no FPGA return** |
| Unused A2–A8 | IC **3–9** → GND |
| Unused Y2–Y8 | IC **17–11** → unconnected, not grounded |
| Cdec | 0.1 µF ceramic across IC **20–10**, shortest possible connections |
| Cbulk | 1 µF ceramic across the input-board supply at its entry |

Use capacitors rated at least 10 V. All identically labeled GND nets in the figure are common. This is a connection diagram, not a physical placement template. Verify connector orientation and actual board revision against the official schematic; do not count holes from the USB connector by assumption. Stop before power-up if 3V3/GND or orientation cannot be identified. The onboard oscillator already connects to FPGA52; no external jumper is needed.

Rs/Rin/Rout are starting values, not clamps or validated termination. Rs is specific to the Nano test source, not an addition to the final PS1 circuit. Keep signals and their ground returns short and close. Long breadboard jumpers do not qualify the final high-frequency assembly.

The manufacturer's pin diagram was visually checked. Looking from above, pins 1–10 run down the left side: /OE1, A1–A8, GND. The opposite side from top to bottom is 20–11: VCC, /OE2, Y1–Y8. Confirm the actual pin-1 mark.

Future assignments: MCLK candidate A1(2)→Y1(18), BCK A2(3)→Y2(17), LRCK A3(4)→Y3(16), DATA A4(5)→Y4(15). **PS1 and Nano input pins 25–28 remain disconnected in this test.** To repeat standalone testing on A2–A4, power off, remove the selected input's ground tie, move the test source and Rpd to that input, ground the previously tested input, and move Rout/Rhold and the probe to its matching output. Never tie outputs together.

## Build

From the repository root:

```sh
make test-input-buffer
make test
```

The first tests the new generator. The second also runs existing PCM/FIFO/S/PDIF regression tests. Neither simulates analog buffer behavior.

### Test signal settings (leave unchanged initially)

The independent test project divides the onboard 27 MHz oscillator without a PLL. It generates a clock waveform, not PCM or S/PDIF.

| `HALF_PERIOD` | Nominal output | Purpose |
|---:|---:|---|
| 5 (default) | 2.7 MHz | Initial dynamic test; not exactly PS1 BCK |
| 306 | Approximately 44.117647 kHz | Slow test; not exactly 44.1 kHz |
| 1 | 13.5 MHz | Optional higher-frequency test |
| 0 | 27 MHz | Direct clock, also active during startup/reset |

Divided outputs have a theoretical 50% duty cycle (equal High and Low durations). Frequency accuracy follows the oscillator; pad duty, delay and amplitude require measurement. Do not use negative parameter values. **13.5/27 MHz testing does not replace exact 16.9344 MHz testing**, PS1 slew/negative-excursion checks, actual loading, four-channel skew or supply-transition qualification. Higher-frequency tests can wait.

### Gowin EDA and programming

1. Disconnect PS1, optical transmitter and all other external circuitry. Initially program the Nano alone.
2. Open `platform/tang_nano_9k/input_buffer_test/input_buffer_test.gprj`, not the normal S/PDIF project.
3. Verify device `GW1NR-LV9QN88PC6/I5` against your board and top `input_buffer_test_top`. Only the two test Verilog files belong in this project.
4. Default output is 2.7 MHz. Change the default `HALF_PERIOD` in this project's `top.v` using the table, then resynthesize and reroute. Leave `STARTUP_BITS=16`. No PLL IP is needed.
5. Run Synthesize and Place & Route. Inspect warnings and reports: input52, output29, LVCMOS33, output DRIVE=4. Check unused-pin settings; they do not replace physically disconnecting peripherals.
6. The SDC defines only the 27 MHz input clock. There is no external synchronous receiver, so external output setup/hold is unspecified. Check clock recognition, internal timing, clock-to-pad paths and explanations for unconstrained paths. This is not completed I/O timing or waveform signoff.
7. In Programmer, verify the detected target and choose **SRAM programming**, selecting this test project's `.fs`. Exact operation labels vary with version. Do not erase or program Flash for this test.
8. Check the Nano source waveform, then power off before adding the buffer board. Removing USB loses the SRAM image. On each power-up, **keep /OE open and reload the test image**: an existing Flash image may boot instead. Do not mistake it for this generator.

Record the frequency setting, build time and selected image. Never connect PS1 or the optical module while this image is loaded. To return to the normal PoC, power off, remove test wiring, select the normal project and recheck all interface prerequisites.

## Procedure

Live enable/disable steps require SW_ENABLE to be a fixed switch wired with power off. If only removable jumper JP_EN1 is available, do not substitute live insertion/removal; establish a safe switching method first. Keep it OPEN for rewiring, power-up and programming; reload the dedicated SRAM image after each dynamic-test power cycle.

### 1. Unpowered checks and supply

Check orientation, shorts, unused-input grounds and the /OE pullup without power. Do not power a persistent low-resistance supply short. Initially leave the Nano signal source disconnected from A1 and remove the enable jumper. Power the buffer only from Nano 3V3/GND, with no second supply.

Measure IC20–10: the evaluation supply range is 3.0–3.6 V. Verify /OE High. Stop immediately for abnormal heating, voltage or supply droop. Never place a current meter directly across the supply.

### 2. Static 0/3V3 and disable

Keep the Nano signal source disconnected. With power off, connect the source side of Rin first to GND, then to 3V3 for separate trials. **Never tie the Nano output to 3V3/GND.**

| A1 | Enable jumper | Expected TP_Y |
|---|---|---|
| GND | Closed | Low |
| 3V3 | Closed | High |
| 3V3 | Open | Hi-Z output; Rhold pulls TP_Y Low after settling |

Allow RC settling. A Low reading alone does not rigorously prove Hi-Z; together with recovery to High when enabled, this is an initial functional check. Never apply supply directly to an output.

### 3. Dynamic 2.7 MHz test

1. Power off, remove static supply/ground jumpers and wire Nano29→Rs→Rin. **Leave the A1 pin disconnected initially**, retaining Rpd at the Rin output. Reload the test image and measure the source frequency/amplitude here. Investigate unexpected levels or negative excursions before connecting the IC.
2. Power off and connect A1. Power up with /OE open and reload. Connect CH2 to TP_A and CH3 to TP_Y. Verify **10X on both physical probes and both scope channel settings**. Other channels are acceptable if recorded.
3. Probe grounds go only to the board's common GND. Treat scope channel grounds as common; never clip ground to a signal. Stay away from mains circuitry.
4. Start with DC coupling, 1 V/div, roughly 100 ns/div, rising-edge trigger on CH2 near 1.5 V. Position the full 0–3.3 V waveform on screen. AUTO may help obtain a display; recheck channel, probe and bandwidth settings afterward.
5. Close /OE. TP_Y should follow TP_A without inversion, with delay, near 2.7 MHz. Reopen /OE and check that Rhold pulls TP_Y Low.
6. Initially record one photo, frequency, High/Low and Vmax/Vmin. Precise delay measurement is not required on day one. Use bandwidth limit OFF for edge/amplitude evaluation; investigate suspicious peaks using a nearby short ground connection. Separate measurement artifacts from actual excursions.

Compare to LCX541 recommended input range 0–5.5 V, VIH≥2.0 V and VIL≤0.8 V. Future FPGA inputs must be checked against the normal LVCMOS33 range -0.3–3.6 V and the same logic thresholds. **Average voltage or Vpp alone is not a pass.** Do not interpret absolute-maximum values as normal operating permissions. Investigate peak magnitude, duration and measurement conditions.

Toshiba's input slew condition is 0–10 ns/V over VIN=0.8–2.0 V at VCC=3.0 V. A scope's standard rise-time measurement, commonly 10–90%, is a different interval and must not be substituted directly.

### 4. Optional additional tests

Rebuild for approximately 44.118 kHz, 13.5 MHz or 27 MHz if needed. Initial timebase suggestions: 5 µs/div, 20 ns/div and 10 ns/div respectively. High-frequency results are sensitive to probe load, ground leads and wiring. Postpone them if the measurement setup is not ready.

For delay, compare the same voltage crossing on input/output and account for probe skew. The specified 1.5–6.5 ns propagation delay applies to the manufacturer's specified supply/load/waveform conditions, not automatically to this fixture.

## Records and sources

Hardware items remain **unmeasured/unperformed**: Gowin build and programming; board revision/orientation/continuity; VCC and /OE levels; static response/disable; dynamic frequency and voltage; high-frequency slew/delay and wiring/probe conditions; A2–A4 repetition and four-channel skew. Record results without personal details, instrument serials or image location metadata.

After basic board testing, evaluate **actual PS1 negative excursions and input slew to decide whether additional protection is needed**. Keep PS1 disconnected until then. Ioff at zero supply does not qualify every startup/shutdown ramp. See the [interface release conditions](ps1-input-interface.en.md#release-conditions).

- Software: `test_clock_divider_tb` checks 0/1/5/306/8 modes, both clock edges, duty, repeated reset and platform startup. Direct mode intentionally passes the clock during reset. Check execution logs for results.
- On 2026-09-12, `make -B test` passed the new test, PCM RX/S/PDIF unit tests, FIFO tests and all eight existing integration/external-decoder configurations. Existing RTL timescale-inheritance warnings remain; the new RTL compiled without warnings. Project file references, local document links and SVG rendering were also checked.
- Hardware: Gowin synthesis/P&R, programming and physical measurements have not been performed. No analog IC simulation is claimed.
- Pinout: [Toshiba-authored Japanese datasheet, distributed by Akizuki](https://akizukidenshi.com/goodsaffix/74LCX541FT_datasheet_ja_20181030.pdf), p.2 §§5–7, visually checked. The PDF is linked, not redistributed.
- Board: [Sipeed official schematic](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf), PDF p.2 / drawing Id 3/5. U16: 3V3-powered 27 MHz via R26 to FPGA52. FPGA29=J5-9, BANK2=3.3 V, J6-23=GND, J6-24=3V3. Verify your board revision before assembly.
- Electrical limits: [Toshiba official datasheet](https://toshiba.semicon-storage.com/info/74LCX541FT_datasheet_en_20181030.pdf?did=15179&prodName=74LCX541FT), [Gowin DS117](https://cdn.gowinsemi.com.cn/DS117E.pdf); see the [Japanese input proposal](ps1-input-interface.md) for extracted conditions.
- The SVG is an original project illustration based on these pin assignments, not a manufacturer-approved finished circuit.
