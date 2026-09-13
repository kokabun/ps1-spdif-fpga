# Input-buffer test record template

[日本語・正本](input-buffer-record.md)

Copy before use. **Start with unmeasured fields; do not fill unperformed tests.** See `docs/input-buffer-measurement.en.md`. Adjust reciprocal language links when adapting this into a public README.

Contents: [Versions and conditions](#versions-and-conditions) / [Prechecks](#prechecks) / [Results](#results) / [Assessment](#assessment) / [Publication](#publication)

## Versions and conditions

| Item | Record |
|---|---|
| Run ID / measurement date (necessary precision only) | Not recorded |
| PS1 / optical / return-to-FPGA wiring | Unchecked; all must be disconnected |
| PoC commit / dirty state | Not recorded |
| Tool version / commit / dirty state | Not recorded |
| Tool source SHA-256 (relative names and hashes) | Not recorded |
| Python version | Not recorded |
| Gowin version / test .fs relative filename and SHA-256 | Not recorded |
| HALF_PERIOD / DRIVE | Unchecked; initial design is 5 / 4 |
| Nano/adapter revision, IC model and orientation | Unchecked |
| R1–R6 and C1/C2 values / changes | Unchecked |
| Fixed SW_ENABLE switch and open/closed operation | Unchecked |
| Signal/GND wiring lengths, relative photo filenames | Not recorded |
| CH2 = TP1/TP_A1; CH3 = TP2/TP_Y1 | Unchecked |
| Probe models (no serials) / physical 10X | Unchecked |
| Scope attenuation, compensation, ground connection | Unchecked |
| Probe skew / deskew | Unchecked / uncorrected |
| Instrument rise/fall thresholds | Unchecked; distinct from analysis 10–90% |
| Instrument firmware (no serials) / wired or wireless LAN | Not recorded |

Do not record IPs, MACs, serials, names, personal email or absolute paths. The manifest does not automatically collect all physical conditions, thresholds, deskew or source versions.

## Prechecks

- [ ] Power-off continuity, shorts, orientation and unused input grounding checked.
- [ ] SW_ENABLE OPEN at power-up and programming.
- [ ] Live enable/disable only via a prewired, secured switch.
- [ ] Dedicated SRAM image reloaded after every dynamic-test power cycle.
- [ ] Nano signal output disconnected during static tests.
- [ ] Physical and instrument attenuation checked on both channels.
- [ ] First CSV/PNG compared with the instrument display.

| Manual check | Value/result |
|---|---|
| IC20–10 VCC | Unmeasured |
| /OE voltage, OPEN / closed | Unmeasured |
| Heating / supply droop | Unchecked |
| Connection, identification, status | Not performed |
| Readback matches requested settings | Unchecked |

## Results

Include units and distinguish screen/instrument/analysis values. A `null` is unavailable, not zero. Never omit skipped cases and claim all tests passed.

| Case ID | Condition | CH2 | CH3 | Result/reason |
|---|---|---|---|---|
| s10-static-low | GND input, enabled | Unmeasured | Unmeasured | Not performed |
| s11-static-high | 3V3 input, enabled | Unmeasured | Unmeasured | Not performed |
| s12-static-disabled | 3V3 input, disabled | Unmeasured | Unmeasured | Not performed |
| s20-source-normal | No IC, NORMAL | Unmeasured | Not applicable | Not performed |
| s21-source-raw10k | No IC, RAW | Unmeasured | Not applicable | Not performed |
| s30-disabled-normal | Clock input, disabled | Unmeasured | Unmeasured | Not performed |
| s31-enabled-normal | Clock input, enabled | Unmeasured | Unmeasured | Not performed |
| s32-enabled-raw10k | Clock input, enabled | Unmeasured | Unmeasured | Not performed |
| s33-disabled-raw10k | Clock input, disabled | Unmeasured | Unmeasured | Not performed |
| s40-enabled-raw100k | Optional, enabled | Unmeasured | Unmeasured | Not performed |
| s41-enabled-raw1m | Optional, enabled | Unmeasured | Unmeasured | Not performed |

For each dynamic case record:

- Relative ZIP / analysis MD/JSON / setup-photo filenames: not recorded.
- Per-channel frequency, High/Low, Vmax/Vmin/Vpp: unmeasured.
- Disabled CH3 Vavg and residual variation: unmeasured.
- Timebase, sample rate, RAW count/interval and CSV time range: unchecked.
- Clipping, trigger location, MAIN versus RAW coverage: unchecked.
- Transfer elapsed seconds and success/failure: unmeasured.
- Analysis warnings/unavailable items and changed conditions: not recorded.

## Assessment

- Non-inverting operation: unchecked.
- Disabled pulldown and re-enable: unchecked; Low alone does not rigorously prove Hi-Z.
- 10–90% rise/fall and delay: unevaluated; reference only until corrections/loading are established.
- 0.8–2.0 V input slew: unevaluated; do not substitute 10–90% rise time.
- Negative/excess peaks versus measurement artifacts: unevaluated.
- Overall: not performed / confirmed scope / needs remeasurement.
- Stop reason and prerequisites for resuming: not recorded.

Standalone success is not permission to connect PS1, proof of audio format or successful FPGA reception. PS1 electrical compatibility, protection, power transitions and four-signal relative timing require separate validation.

## Publication

- [ ] Reviewed originals, image contents/metadata, CSV/JSON, analysis text and filenames for unnecessary identifiers.
- [ ] Selected only necessary information.
- [ ] Distinguished measurements, hypotheses, unknowns and mock checks.
- [ ] Obtained user approval of selected content/disclosure scope.
- [ ] Checked Japanese README, related-document and translation links.

Selected relative filenames and review scope: not recorded. Preserve local originals without replacement.
