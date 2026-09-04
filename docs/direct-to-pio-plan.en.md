# Plan: direct SPU connection first, PIO breakout later

[日本語・正本](direct-to-pio-plan.md) / [README](../README.en.md)

Updated 2026-09-04. The Japanese version is authoritative. This is a staged work plan, not an unverified solder-point instruction.

## Sequence

First complete S/PDIF output using a direct SPU connection, without using any PIO signal. Then move the connection through the PIO debug board. Use Tang Nano 9K as the initial PoC target. Build separate direct and PIO bitstreams; a runtime clock selector is not required.

RTL synthesis maps the design into FPGA LUTs, registers and other resources. Reuse the PCM receiver, FIFO and S/PDIF transmitter, while selecting the appropriate pins, clock cadence and measured PCM timing for each wiring arrangement.

## Current implementation boundary

This repository contains the original direct-SPU PoC, assuming 384Fs. The PCB repository has a separate integration branch, `feat/pio-spdif-integration`, commit `793d647`, with corrected FIFO full detection, PCM bit placement, stereo pairing and additional tests. Those fixes have not been ported back into this PoC by this documentation change. Port and re-test them for the direct profile before using it.

The integration simulations do not demonstrate electrical compatibility, real clock synchronization, Gowin timing closure or optical receiver lock.

## Stage 1: direct connection

```text
SPU WCKO / BCKO / LRCO / DATO + digital ground
    → required buffering / voltage compatibility
    → Tang Nano 9K → PLT133/T10W → optical receiver
```

1. Identify the console board revision, IC orientation and existing modifications.
2. Measure voltage, clocks and PCM timing before connecting the FPGA.
3. Produce a board-specific soldering diagram and continuity table. Prefer suitable pads where available; do not turn candidate IC pin numbers into confirmed instructions.
4. With power disconnected, attach the confirmed signals and ground, secure the wiring, and inspect for bridges, adjacent-pin contact and shorts. The power-supply board is outside the work scope.
5. Re-measure at the FPGA side after buffering, including edge, LRCLK polarity, slot length and input timing.
6. Apply the corrected RTL and direct pin/timing profile; verify known PCM by decoding the emitted S/PDIF.
7. Synthesize, place and route, review timing/CDC, then generate the direct bitstream.
8. Verify optical output, stereo identity, startup/reset, silence, FIFO faults and sustained operation.

If WCKO is confirmed as 16.9344MHz synchronized with 44.1kHz audio, use 384Fs and one BMC half-bit update per three clock cycles. No internal wiring to PIO is needed in this stage.

## Stage 2: move to the PIO debug board

Choose the route based on Stage 1 measurements:

| Option | Wiring | FPGA configuration | Remaining verification |
|---|---|---|---|
| A: existing PCB concept | Add DATO to candidate PIO31; use PIO32 SYSCLK1, PIO33 BCLK and PIO66 LRCLK | Six-cycle update if SYSCLK1 is verified as 768Fs | PCM/PIO-clock alignment and sustained synchronization |
| B: also bring out WCKO | Add WCKO to a verified unused contact and add an adapter receive path | Three-cycle update if WCKO remains 384Fs | Contact availability, clock routing and BCLK/LRCLK alignment |

PIO65 is only a candidate. The current adapter has no PIO65-to-FPGA receive path. Adding WCKO does not itself prove that the existing PIO audio clocks match DATO. Revisit wiring if they do not.

The connector does not convert clock frequency. Fixing one source and using its dedicated bitstream avoids a runtime selector. Never tie independent clock outputs together.

Before soldering, check connector orientation, cable continuity, power and modifications such as PSIO contact reuse. Produce a unified console-to-adapter wiring table, including which direct wires are removed or retained and their loading. R4 on the current PIO31 path is initially DNP; populate it only after confirming the intended signal and voltage.

Keep the existing receive-enable jumper JP1 open during startup/reprogramming; enable after configuring FPGA inputs. This remains a manual procedure and does not disconnect input loading. Measure timing again at the FPGA; do not reuse direct-wire delays for the longer PIO path. Generate a separate PIO bitstream and compare the same known PCM against the direct result.

## Deliverables and immediate next work

For each stage retain the soldering/wiring diagram, measurements, CST/SDC and PCM parameters, source revision, dedicated bitstream and validation record. Mark unknowns as TBD and omit personal or machine-identifying data from public records.

The next work is the direct-SPU stage: identify the actual board and pickup points, prepare measurements, port the corrected RTL, and document direct-bitstream generation. PIO wiring and adapter changes follow those results.
