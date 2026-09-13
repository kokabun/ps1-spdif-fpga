# PS1 input interface: 74LCX541FT evaluation proposal

[日本語・正本](ps1-input-interface.md) / [README](../README.en.md)

2026-09-10. This is a summary translation; the Japanese document is authoritative. Design review only, not released for PS1 connection.

Contents: [Proposal](#proposal) / [Release conditions](#release-conditions) / [Construction layout](#construction-layout-illustration)

## Proposal

Use four non-inverting channels of a Toshiba 74LCX541FT between PS1 MCLK/BCK/LRCK/DATA and Nano inputs 25/26/27/28 respectively. Power the buffer from Nano 3V3, with common signal ground and no PS1 power connection. The device has 5.5 V tolerant inputs and power-down protection; consult the manufacturer sources linked in the Japanese document for limits and test conditions.

Proposed starting values per channel: 100 Ω before the buffer input, 33 Ω immediately after its output, 100 kΩ input pulldown and 100 kΩ FPGA-side pulldown. These are evaluation values, not validated termination or negative-voltage protection. Add 0.1 µF directly across the IC supply and an auxiliary 1 µF. Tie both active-low enables together, pull up with 10 kΩ and use a normally-open switch to ground for enable. A removable jumper may be used only when power is off; use a fixed, prewired switch for live enable/disable steps. Ground unused inputs; leave unused outputs open. Keep the FPGA signal connector disconnected during initial buffer testing.

Akizuki candidates: [114112 buffer](https://akizukidenshi.com/catalog/g/g114112/) and [110497 adapter](https://akizukidenshi.com/catalog/g/g110497/). Verify package dimensions and pin orientation before assembly. On 2026-09-12 the manufacturer's pin diagram was visually checked and a [PS1-disconnected test procedure with numbered wiring](input-buffer-test.en.md) was added. Adapter hole mapping and physical orientation still require assembly checks. **Verified pin numbers do not establish electrical compatibility or authorize PS1 connection.**

## Release conditions

The recorded LRCK minimum, -549.86 mV, is below this buffer's -0.5 V absolute minimum. Its origin has not been separated from long-ground-lead measurement effects. Actual input slew also remains unchecked. Neither direct connection nor an assumed clamp circuit is approved.

First check PS1 voltage, negative excursions and input slew using a short ground reference. Separately test the input board without PS1. After input compatibility or an appropriate protection circuit is established, evaluate PS1-to-buffer with FPGA signal pins disconnected; then verify FPGA-side waveforms before connection. Start with Nano on first and PS1 second, enable only after both stabilize, disable before shutdown, and turn PS1 off before Nano. Check partial-power and ramp behavior separately; Ioff is not galvanic isolation or a guarantee over every supply ramp.

Audio format details can be resolved during FPGA capture after electrical qualification. The Japanese document contains component values, detailed conditions and primary-source links.

## Construction-layout illustration

The [authoritative Japanese build guide](ps1-input-interface.md#ブレッドボード構築イメージ) uses the same part numbers in its schematic and four breadboard views: [component positions](images/lcx541-input-breadboard-layout.svg), [power/ground](images/lcx541-input-breadboard-power.svg), [enable](images/lcx541-input-breadboard-enable.svg), and [signals/test points](images/lcx541-input-breadboard-signal.svg). Images have Japanese labels. Long crossing wires are replaced with endpoint labels: connect the two endpoints identified by each W number with one insulated jumper. Thin pale lines within each five-hole strip represent internal board connections, not extra wires.

| Part | Role | Placement example |
|---|---|---|
| MOD1 / BB1 | Nano 9K / breadboard | Nano stays outside the breadboard |
| U1 / AD1 | 74LCX541FT / AE-SSOP20 | D5–D14: IC pins 1–10; H5–H14: pins 20–11 |
| R1 | Rs, 33 Ω | At Nano FPGA29/J5-9; W11 connects its far end to B2 |
| R2 | Rin1, 100 Ω | A2–A6 |
| R3 | Rpd1, 100 kΩ | B3–B6 |
| R4 | Rout1, 33 Ω | I7–I17; body near I7, extend the test-point-side lead |
| R5 | Rhold1, 100 kΩ | F17–F21 |
| R6 | R_ENABLE, 10 kΩ | C1–C5 |
| C1 | Cdec, 0.1 µF ceramic | J4–J5, shortest wiring close to the IC |
| C2 | Cbulk, 1 µF ceramic | Separate free holes in the verified left +/− supply-entry rail groups |
| JP_EN1 | SW_ENABLE removable jumper | J6–J15, initially absent |
| TP1 / TP2 | TP_A1 input / TP_Y1 output | C6 / J17: CH2 / CH3 probe tips |
| TP3 / TP4 | Probe grounds | D3 / G21 |

| Wire | Endpoints |
|---|---|
| W01 / W02 | Nano 3V3 (J6-24) → left + / GND (J6-23) → left − |
| W03 / W04 | I5 → right + / A1 → left + |
| W05 / W06 | E3 → left − / I4 → right − |
| W07 / W08 / W09 | A14 → left − / F15 → right − / J21 → right − |
| W10 | A5 ↔ I6, tying both /OE pins together |
| W11 | R1 far end → B2 |
| W12–W14 | A7/A8/A9 → left −, removable unused A2–A4 grounds |
| W15–W18 | A10/A11/A12/A13 → left −, unused A5–A8 grounds |
| W19 / W20 | Left + ↔ right + / left − ↔ right − |

Bridge used rail segments and corresponding left/right polarities with separate jumpers, checking continuity before use. Do not assume EIC-801 five-hole power groups are continuous. Nano supply, C2, and bridge wires must use separate holes; rail insets are logical illustrations, not physical hole maps.

**Changed from the previous layout:** R4 moved from I7–I3 to I7–I17, R5 from F3–F1 to F17–F21, and output TP_Y1 from J3 to J17. Output ground now uses right-side row 21; do not retain the previous right-side row 1/3 output wiring. Input ground enters at E3 and the common /OE jumper now uses A5–I6, keeping connections accessible. Circuit topology and component values are unchanged.

Assume an EIC-801-style 30-row board, displaying rows 1–24. Each A–E and F–J strip is internally connected but separated by the central gap. Verify that the assembled 2.54 mm/600 mil adapter naturally fits the illustrated D/H columns without bending pins. IC pin numbers, part references (e.g. R2), and hole coordinates (e.g. A6) are different identifiers. Never share one hole between component leads and jumpers.

With USB disconnected, check solder joints, orientation, adapter mapping, rail bridges and shorts. Install power/ground and R6/W10, leave JP_EN1 and W11 disconnected, ground unused inputs, and leave unused outputs open. Follow the [test procedure](input-buffer-test.en.md#procedure) for supply, static and dynamic testing. Source-only measurement requires the A1 path open; with this layout, remove AD1 with power off, retaining R1–R3 and TP1. The signal diagram shows the later connected dynamic-test state.

Keep the R4 body close to the IC and insulate extended exposed leads where needed. Check real component dimensions before insertion and revise/verify endpoints if moving parts. This fixture starts with approximately 2.7 MHz basic testing; it does not qualify final high-frequency wiring. Keep PS1, the optical transmitter and Nano inputs 25–28 disconnected. Remove the relevant W12–W14 ground jumper, with USB disconnected, before later using A2–A4 for signals.
