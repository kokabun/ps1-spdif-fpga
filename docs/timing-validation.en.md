# Timing constraints and waveform validation for the direct PoC

[日本語](timing-validation.md) / [README](../README.en.md)

Japanese is authoritative. The SDC is an unmeasured template, not completed hardware constraints or timing closure. Clock periods alone do not cover input or cross-domain paths.

## Values to measure

Measure at the FPGA inputs through the final buffers and cables, using an oscilloscope (the developer uses a DHO914S). Follow the README voltage checks before connecting.

| Item | Status | Use |
|---|---|---|
| WCKO period, shortest period, duty cycle, variation | 16.806 MHz photographed and 16.949 MHz observed immediately beforehand at the ConsoleMods-labelled MCLK point; identity with WCKO, 384 Fs, shortest period, duty and variation are TBD | `create_clock`, optional `-waveform`, uncertainty |
| BCKO period, shortest period, duty cycle, variation | 2.8225 MHz observed; shortest period, duty and variation TBD | `create_clock`, optional `-waveform`, uncertainty |
| DATO launch reference edge and earliest/latest arrival | A single acquisition during audio playback showed DATO transitions near BCKO falling edges; rising-edge capture is the leading candidate. Inter-probe skew and exact setup/hold are TBD | BCKO-relative `set_input_delay -min/-max` |
| LRCO frequency, launch reference edge and earliest/latest arrival | 44.097 kHz observed; edge/timing TBD | Separate `set_input_delay -min/-max` |
| LRCO polarity, slot boundary, capture edge | TBD | Top parameters, stimulus, STA capture edge |
| WCKO/BCKO ratio, phase relationship, stop/restart behavior | Latest MCLK/BCKO ratio approximately 5.954; preceding value approximately 6.005. Exact ratio, phase, synchronization and stop/restart behavior are TBD | Clock relationship model and sustained testing |

Include data/clock routing differences, buffer delay, measurement error and variation margins. `-clock_fall` selects the input-delay reference edge, independently of the RTL capture edge. Check that synthesis recognizes the inverted RX clock when using negative-edge capture. Typical measurements alone are not guaranteed bounds for every operating condition.

On 2026-09-06, a DHO914S measurement of the ConsoleMods-labelled LRCK/BCK/MCLK points on an
SCPH-7000 / PU-20 observed LRCO at 44.097 kHz, BCKO at 2.8225 MHz and an LRCO/BCKO ratio of
approximately 64.01. MCLK displayed 16.806 MHz in the published photograph and 16.949 MHz
immediately beforehand. It is therefore recorded as an approximately 16.8--16.95 MHz clock
candidate; nominal 16.9344 MHz, 384 Fs and an exact 6:1 relationship to BCKO remain unconfirmed.
See the [README hardware evidence](../README.en.md#lrco--bcko--dato--mclk-measurement-evidence-2026-09-06)
for photographs and conditions. The LRCO/BCKO frequencies and 64 Fs relationship are treated as
confirmed, but peak voltages observed with the long alligator ground lead are not FPGA terminal
guarantees or evidence that a direct connection is safe.

In a single acquisition during audio-CD playback on the same date, DATO transitioned near BCKO
falling edges and appeared stable near rising edges. BCKO rising-edge capture is therefore the
current RTL candidate. Long-ground-lead effects, inter-probe skew and the limited acquisition set
remain, so exact setup/hold, capture edge, slot boundaries and Right-Justified bit positions are TBD.

## FIFO and reset clock-domain crossings

These are RTL logical names. Resolve actual synthesized names and bit counts in the Gowin netlist; reject empty or unexpectedly broad constraint matches.

| Path | Check |
|---|---|
| `fifo.wr_gray` → `fifo.wr_gray_r1` | Actual delay and skew of every RX→TX pointer bit |
| `fifo.rd_gray` → `fifo.rd_gray_w1` | Actual delay and skew of every TX→RX pointer bit |
| Each first synchronizer stage → second stage | Destination-clock setup/hold, preserved stages and placement |
| FIFO `mem` → TX `frame_q`/`word_q` | Memory inference, data settling before read permission, actual data-path delay |
| `reset_release` and domain resets | Preserved two-stage release, recovery/removal, POR and late-starting clocks |

Gray pointers change one logical bit at a time, but routing skew can overlap different updates. Establish a delay budget below the shortest source-clock period with margin and check every bit in both directions. The SDC `set_max_delay` examples are syntax templates, not a guarantee of physical skew. Inspect how Gowin accounts for clock latency and check the actual data-path delays.

Do not finish by applying blanket `set_false_path` or asynchronous `set_clock_groups` constraints. Scope required exceptions narrowly and verify that they do not disable pointer delay constraints. Do not assume another vendor's `-datapath_only` or `ASYNC_REG` semantics apply to Gowin. Confirm preservation and placement methods against the selected EDA version and synthesized design.

## Before generating a hardware bitstream

1. Record measured values and margins; resolve SDC placeholders and top parameters.
2. Check WCKO/BCKO routing resources after synthesis. Pins 25/26 are general I/O; verified pin numbers and voltages do not prove suitable clock routing.
3. Explicitly use `LVCMOS18` for LED pins 15/16, matching the schematic's 1.8 V Bank 3.
4. Inspect routed clocks, input setup/hold, CDC paths, resets and exception coverage. Maximum frequency alone is insufficient.
5. S/PDIF has no separate receiver clock pin. Do not invent output-delay values; measure pulse widths, waveform and optical interoperability. Document exclusions for asynchronous outputs such as LEDs.
6. Associate EDA version, source commit, board, measurements, constraints and routing reports. Test startup, reset and sustained operation on hardware.

Gowin synthesis/place-and-route and hardware validation remain incomplete. Resolve measurements before hardware testing.

## Simulation coverage

`make test` checks eight PCM configurations and output stability throughout each half-bit at every recorded TX clock cycle. The first transition establishes the half-bit phase without assuming reset latency. Tests corrupt each of the following two cycles independently and require rejection, while accepting changed reset latency. This is cycle-level logic verification, not a test for sub-cycle glitches, metastability or physical routing delay.

At 44.1kHz the half-bit rate is 5.6448MHz and its width is approximately 177.15ns. Actual BMC transitions depend on data and preambles; they are not always 5.6448M transitions per second.

## Official references

- [Gowin Design Timing Constraints User Guide SUG940](https://cdn.gowinsemi.com.cn/SUG940E.pdf): clocks, I/O delays, exceptions and STA reports.
- [Sipeed Tang Nano 9K schematic](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf): pins and bank supplies.
