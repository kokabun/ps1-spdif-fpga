# PS1 input interface: 74LCX541FT evaluation proposal

[日本語・正本](ps1-input-interface.md) / [README](../README.en.md)

2026-09-10. This is a summary translation; the Japanese document is authoritative. Design review only, not released for PS1 connection.

Contents: [Proposal](#proposal) / [Release conditions](#release-conditions)

## Proposal

Use four non-inverting channels of a Toshiba 74LCX541FT between PS1 MCLK/BCK/LRCK/DATA and Nano inputs 25/26/27/28 respectively. Power the buffer from Nano 3V3, with common signal ground and no PS1 power connection. The device has 5.5 V tolerant inputs and power-down protection; consult the manufacturer sources linked in the Japanese document for limits and test conditions.

Proposed starting values per channel: 100 Ω before the buffer input, 33 Ω immediately after its output, 100 kΩ input pulldown and 100 kΩ FPGA-side pulldown. These are evaluation values, not validated termination or negative-voltage protection. Add 0.1 µF directly across the IC supply and an auxiliary 1 µF. Tie both active-low enables together, pull up with 10 kΩ and use a normally-open switch to ground for enable. Ground unused inputs; leave unused outputs open. Keep the FPGA signal connector disconnected during initial buffer testing.

Akizuki candidates: [114112 buffer](https://akizukidenshi.com/catalog/g/g114112/) and [110497 adapter](https://akizukidenshi.com/catalog/g/g110497/). Verify package dimensions and pin orientation before assembly. The logical connection proposal is not a numbered construction schematic: the IC pin diagram still needs visual verification. No order has been placed.

## Release conditions

The recorded LRCK minimum, -549.86 mV, is below this buffer's -0.5 V absolute minimum. Its origin has not been separated from long-ground-lead measurement effects. Actual input slew also remains unchecked. Neither direct connection nor an assumed clamp circuit is approved.

First check PS1 voltage, negative excursions and input slew using a short ground reference. Separately test the input board without PS1. After input compatibility or an appropriate protection circuit is established, evaluate PS1-to-buffer with FPGA signal pins disconnected; then verify FPGA-side waveforms before connection. Start with Nano on first and PS1 second, enable only after both stabilize, disable before shutdown, and turn PS1 off before Nano. Check partial-power and ramp behavior separately; Ioff is not galvanic isolation or a guarantee over every supply ramp.

Audio format details can be resolved during FPGA capture after electrical qualification. The Japanese document contains component values, detailed conditions and primary-source links.
