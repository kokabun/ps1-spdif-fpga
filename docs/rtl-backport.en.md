# Common RTL fixes backported to the direct PoC

[日本語](rtl-backport.md) / [README](../README.en.md)

2026-09-04. Japanese is authoritative.

## Provenance and scope

Selectively backported common fixes from `ps1-pio-lab-pcb` integration commit
`793d647`, `fpga/spdif/rtl/`. This returns fixes to PoC-derived MIT RTL; it does
not merge or relicense the whole PCB project. FIFO/integration stimuli and the
external decoder from that commit are adapted for the direct profile only.
PIO constraints, wrappers, configuration generator and 768Fs/six-cycle mode are excluded.

## Changes

- Register FIFO full state to break the combinational next-pointer dependency.
- Place PCM in bits 12–27; accept left and buffer right from the same stereo pair.
  Align ready with the actual FIFO consumption edge.
- Mute both channels on underflow, assert Validity, and compute even parity from
  the complete payload.
- Generate preambles relative to the previous output polarity; this does not
  claim the previous fixed polarity was always incorrect.
- Reject startup partial slots; require an observed boundary and at least 16
  samples per complete slot before assembling a pair.
- Use the selected RX edge for FIFO writes and overflow detection.
- Add asynchronous reset assertion and domain-local synchronous release, with
  a shared reset initializing both domains.
- Add the reset module to the Gowin project source list. No changes to the 9K
  top, clock wrapper or CST/SDC.

The interface remains 384Fs with a half-bit enable every three cycles. Real
console edge, polarity and voltage are still unverified.

## Verification and limitations

`make -B test` passes two legacy unit tests, FIFO tests and eight direct cases:
two edges × two polarities × 16/32-bit slots. Each case decodes 419 stereo
pairs solely from emitted S/PDIF, checking sequence, placement, pairing, even
parity, U/C, Z/X/Y and polarity, block wrap, underflow muting and Validity.
FIFO tests cover four-entry capacity, rejected writes while full, order, wrap
and reset. Legacy failures now use `$fatal` for nonzero exit status.

The former two unit-test passes did not establish these properties. This is
still not complete IEC 60958 compliance or coverage of every asynchronous
phase, power condition, signal-integrity issue or optical receiver. Clock-loss
monitoring and adaptation to unknown formats/delays are not added. Gowin
synthesis/place-and-route was not run; inherited-timescale warnings remain.
