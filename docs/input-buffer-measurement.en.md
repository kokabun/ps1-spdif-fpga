# Input-buffer measurements and records with the DHO914S CLI

[日本語・正本](input-buffer-measurement.md) / [Circuit and overview](input-buffer-test.en.md) / [Public evidence](evidence/input-buffer/README.en.md)

Created 2026-09-13. Japanese is authoritative. **This procedure has not been exercised on hardware.** Disconnect PS1 and the optical transmitter, and do not connect the LCX541 output back to an FPGA input.

## Contents

- [0. Preconditions](#before)
- [1. PC environment](#setup)
- [2. Create a run folder](#folders)
- [3. Connection and settings](#connect)
- [4. Static tests](#static)
- [5. Source-only tests](#source)
- [6. Capture input and output](#dynamic)
- [7. Offline analysis](#analysis)
- [8. Optional larger RAW captures](#larger)
- [9. Finish, resume and publish](#finish)
- [Validation and tool changes](#validation)

<a id="before"></a>
## 0. Preconditions

This adds recording operations to the [assembly, wiring, programming and electrical criteria](input-buffer-test.en.md). **Run one command block at a time, not the entire document. Stop at every Check and on every error.** A multiline block is one command; include its trailing backslashes.

- Disconnect USB power before rewiring, inserting/removing the adapter or moving probes. Ground clips go only to verified common board GND. Never disconnect scope protective earth.
- Power up/program with `/OE` OPEN (disabled). USB removal loses the SRAM test image; reload the dedicated test image after every power cycle during dynamic tests. Do not mistake the image booted from Flash for the test image.
- **Enable/disable steps assume SW_ENABLE is a fixed switch, wired and secured with power off.** Open means disabled, closed means enabled. If only removable jumper JP_EN1 is available, do not substitute live jumper insertion/removal: establish a safe switching method first. The CLI cannot operate `/OE`.
- Stop and remove power for uncertain wiring, heating, supply droop or unexpected voltages.
- Check probe compensation and both physical 10X switches. Precision delay is optional; record uncorrected probe skew as uncorrected.

| Scope connection | Test point | Current layout hole |
|---|---|---|
| CH2 tip | TP1 = TP_A1, A1 input | C6 |
| CH3 tip | TP2 = TP_Y1, after Rout | J17, not old J3 |
| CH2 / CH3 ground | TP3 / TP4, common GND | D3 / G21 |

Use hole coordinates only after matching the physical board to the [layout](ps1-input-interface.en.md). For source-only testing remove AD1, retain R1–R3 and TP1, and record that configuration.

<a id="setup"></a>
## 1. PC environment

Commands use Bash on macOS. The tool checkout is assumed to be the sibling `rigol-dho914s-tools`; adjust its installation path if necessary. **All subsequent commands run from the ps1-spdif-fpga root**, not the tool checkout.

1. Start Bash.

```bash
bash
```

2. Change to this project; adapt the example checkout location if needed.

```bash
cd "$HOME/git/ps1-spdif-fpga"
```

3. Check Python. This example follows the tool README's 3.14 setup. If missing, follow that setup first. An existing suitable environment (Python 3.10+) need not be recreated.

```bash
python3.14 --version
```

4. **Only if .venv does not already exist**, create it. Do not delete/overwrite an existing environment.

```bash
python3.14 -m venv .venv
```

5. Install the local tool into this project's environment. Dependency downloads may require network access; this is not measurement-data upload.

```bash
.venv/bin/python -m pip install -e ../rigol-dho914s-tools
```

```bash
.venv/bin/python -m pip check
```

6. Check available options.

```bash
.venv/bin/dho session --help
```

```bash
.venv/bin/dho analyze-session --help
```

Require `--output`, `--condition`, `--channel-items`, `--chunk-points` and analysis `--markdown` / `--json`. Stop if absent and check the loaded version. These instructions target the 0.3.0 changes.

<a id="folders"></a>
## 2. Create a run folder

All files stay inside this project; **unreviewed originals are not added to Git**.

```text
captures/input-buffer/                 # Only README translations tracked
└── ibuf-001/                          # One run; Git-ignored
    ├── input-buffer-record.md         # Conditions, readings, decisions
    ├── input-buffer-record.en.md
    ├── sessions/                      # Original scope ZIPs
    ├── analysis/                      # Derived Markdown/JSON
    ├── photos/                        # Original setup photographs
    └── review/                        # Local extraction/review

docs/evidence/input-buffer/            # Reviewed publication material only
└── ibuf-001/                          # Created at publication; no results yet
```

1. Choose an unused ID; use `ibuf-002` for another run. Personal names or dates are unnecessary in filenames.

```bash
IBUF_RUN=ibuf-001
```

2. Create the run folder. **Stop if it already exists.** Use a new ID for a new run, or follow [resume](#resume).

```bash
mkdir "captures/input-buffer/$IBUF_RUN"
```

3. Create subfolders.

```bash
mkdir -p "captures/input-buffer/$IBUF_RUN/sessions" "captures/input-buffer/$IBUF_RUN/analysis" "captures/input-buffer/$IBUF_RUN/photos" "captures/input-buffer/$IBUF_RUN/review"
```

4. Copy the record templates; `-n` avoids replacement.

```bash
cp -n docs/templates/input-buffer-record.md "captures/input-buffer/$IBUF_RUN/input-buffer-record.md"
```

```bash
cp -n docs/templates/input-buffer-record.en.md "captures/input-buffer/$IBUF_RUN/input-buffer-record.en.md"
```

5. Verify ignore rules. Both paths and matching rules must be shown; otherwise fix protection before saving.

```bash
git check-ignore -v "captures/input-buffer/$IBUF_RUN/sessions/check.zip" ".venv/bin/dho"
```

6. Record versions in the template. Do not publish entire command outputs without review.

```bash
.venv/bin/python --version
```

```bash
.venv/bin/python -c "import importlib.metadata as m; print(m.version('rigol-dho914s-tools'))"
```

```bash
git rev-parse HEAD
```

```bash
git status --short
```

```bash
git -C ../rigol-dho914s-tools rev-parse HEAD
```

```bash
git -C ../rigol-dho914s-tools status --short
```

Commit IDs alone do not identify dirty tool/FPGA checkouts. Record modifications, do not change either during measurement, and retain tool source SHA-256 values.

```bash
shasum -a 256 ../rigol-dho914s-tools/src/rigol_dho914s/*.py ../rigol-dho914s-tools/pyproject.toml
```

Record Gowin version, `HALF_PERIOD=5`, DRIVE, and the actual test `.fs` filename/hash. Replace the following placeholder with its actual **relative path** before running.

```bash
shasum -a 256 "<relative-path-to-generated-test-image.fs>"
```

<a id="connect"></a>
## 3. Connection and settings

**Physical prerequisites:** complete the power-off checks and supply test in the [circuit procedure](input-buffer-test.en.md), recording supply and `/OE` levels. Keep Nano's signal output disconnected from A1 for static tests. Follow the tool README for PC/scope LAN setup.

1. Execute the following, type the IPv4 displayed on the scope, then Enter. Input is hidden; do not embed the address in command history or documents.

```bash
read -r -s DHO_HOST
```

```bash
export DHO_HOST
```

2. Identify the model and read current settings.

```bash
.venv/bin/dho idn
```

```bash
.venv/bin/dho status --channels 2 3
```

Stop on model/communication errors; do not discover hosts automatically. Check CH2/CH3 amplitude units are **VOLT** on the scope. The CLI cannot change those units; change them on the instrument if needed.

3. Verify both physical probes are at **10X**, then configure. The initial 1 V/div setting is for this 0–3.3 V fixture, not unknown PS1 signals.

```bash
.venv/bin/dho config channel --channel 2 --display ON --probe 10 --coupling DC --scale 1 --offset 0 --bandwidth OFF --invert OFF
```

```bash
.venv/bin/dho config channel --channel 3 --display ON --probe 10 --coupling DC --scale 1 --offset 0 --bandwidth OFF --invert OFF
```

Turn unused CH1/CH4 displays off. Do not leave their probes connected elsewhere.

```bash
.venv/bin/dho config channel --channel 1 --display OFF
```

```bash
.venv/bin/dho config channel --channel 4 --display OFF
```

4. Begin with a static-test timebase and AUTO triggering, which updates the display without periodic edges.

```bash
.venv/bin/dho config timebase --scale 0.001 --offset 0
```

```bash
.venv/bin/dho config trigger --source 2 --slope POS --level 1.5 --sweep AUTO
```

```bash
.venv/bin/dho config acquisition --type NORM --memory-depth 10k --area MAIN
```

```bash
.venv/bin/dho status --channels 2 3
```

**Check:** read back 10X, DC, VOLT, bandwidth OFF, inversion OFF, NORM and MAIN. Adjust position/scale on the scope if clipped and record changes. A failed configuration can be partially applied; recheck before proceeding.

<a id="static"></a>
## 4. Static tests

Follow the [static circuit procedure](input-buffer-test.en.md). Disconnect USB before changing the source side of Rin. Keep the Nano signal output disconnected in every static case. Start each power-up with the switch OPEN and enable using the prewired switch only where required.

### 4-1. Ground input, output enabled

After physical wiring, power and switch checks:

```bash
.venv/bin/dho acquire run
```

**Check: CH2 and CH3 are Low and fully visible.** Start with a 1,000-point NORMAL capture to compare saved data with the instrument.

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s10-static-low" \
  --condition "input=GND; /OE=enabled" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=vavg,vmax,vmin,vpp \
  --channel-items 3=vavg,vmax,vmin,vpp \
  --mode normal --points 1000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s10-static-low.zip"
```

### 4-2. 3V3 input, output enabled

Power off to move the input to 3V3, then use the specified power-up/enable sequence.

```bash
.venv/bin/dho acquire run
```

**Check: CH2 and CH3 are High.**

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s11-static-high" \
  --condition "input=3V3; /OE=enabled" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=vavg,vmax,vmin,vpp \
  --channel-items 3=vavg,vmax,vmin,vpp \
  --mode normal --points 1000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s11-static-high.zip"
```

### 4-3. 3V3 input, output disabled

Open the prewired switch and allow settling.

```bash
.venv/bin/dho acquire run
```

**Check: CH2 stays High and Rhold pulls CH3 Low.** Low alone does not rigorously prove Hi-Z.

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s12-static-disabled" \
  --condition "input=3V3; /OE=disabled" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=vavg,vmax,vmin,vpp \
  --channel-items 3=vavg,vmax,vmin,vpp \
  --mode normal --points 1000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s12-static-disabled.zip"
```

Record voltages and observations. Extract ZIPs using the [local review steps](#review) and compare the PNG, CSV voltages and time axis with the instrument. NORMAL is screen-oriented data, not precision edge-timing evidence.

<a id="source"></a>
## 5. Source-only tests

**Physical steps:** remove power, remove static 3V3/GND input wires, remove AD1 and retain R1–R3/TP1 as in the layout. Reload the dedicated 2.7 MHz Nano image. Use CH2 at TP1; CH3 is not used.

```bash
.venv/bin/dho config channel --channel 3 --display OFF
```

```bash
.venv/bin/dho config timebase --scale 0.0000001 --offset 0
```

```bash
.venv/bin/dho config trigger --source 2 --slope POS --level 1.5 --sweep AUTO
```

```bash
.venv/bin/dho config acquisition --type NORM --memory-depth 10k --area MAIN
```

```bash
.venv/bin/dho acquire run
```

**Check:** approximately 2.7 MHz, intended amplitude and several visible periods. Investigate unexpected peaks or negative excursions, including measurement artifacts, before connecting LCX541.

```bash
.venv/bin/dho --timeout 120 session --channels 2 \
  --point 2=TP_A1 \
  --stage baseline --condition "case=s20-source-normal" \
  --condition "circuit=source-only; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --mode normal --points 1000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s20-source-normal.zip"
```

Check a small RAW transfer next. Acquire a fresh waveform.

```bash
.venv/bin/dho acquire run
```

**Check: the intended signal has been freshly acquired.**

```bash
.venv/bin/dho --timeout 120 session --channels 2 \
  --point 2=TP_A1 \
  --stage baseline --condition "case=s21-source-raw10k" \
  --condition "circuit=source-only; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --mode raw --points 10000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s21-source-raw10k.zip"
```

RAW exports from the beginning of memory, not just the screen center. If requested points cannot be applied, inspect depth, sample rate and timebase, correct settings and reacquire. Successful transfer alone does not mean a valid signal.

<a id="dynamic"></a>
## 6. Capture input and output

### 6-1. Start disabled

**Physical steps:** power off, reinstall AD1, verify A1/Y1/common-ground wiring. Power up with the switch OPEN and reload the test image. CH2 = TP1, CH3 = TP2; recheck physical 10X.

```bash
.venv/bin/dho config channel --channel 3 --display ON --probe 10 --coupling DC --scale 1 --offset 0 --bandwidth OFF --invert OFF
```

```bash
.venv/bin/dho config acquisition --type NORM --memory-depth 10k --area MAIN
```

```bash
.venv/bin/dho status --channels 2 3
```

```bash
.venv/bin/dho acquire run
```

**Check: CH2 is a clock and CH3 is Low.** Both waveforms must fit on screen. Adding a channel may change sample rate.

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s30-disabled-normal" \
  --condition "/OE=disabled; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --channel-items 3=vavg,vmax,vmin,vpp \
  --mode normal --points 1000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s30-disabled-normal.zip"
```

### 6-2. Enable

Close the prewired switch. If using only a removable jumper, stop and return to [preconditions](#before).

```bash
.venv/bin/dho acquire run
```

**Check: CH3 follows CH2 without inversion; both are near 2.7 MHz.**

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s31-enabled-normal" \
  --condition "/OE=enabled; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --channel-items 3=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --mode normal --points 1000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s31-enabled-normal.zip"
```

Capture RAW under the same settings. NORMAL and RAW here are separate acquisitions.

```bash
.venv/bin/dho acquire run
```

**Check: fresh, unclipped waveforms.**

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s32-enabled-raw10k" \
  --condition "/OE=enabled; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --channel-items 3=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --mode raw --points 10000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s32-enabled-raw10k.zip"
```

### 6-3. Disable again

Open the switch, keeping channel/timebase/depth settings unchanged for comparison.

```bash
.venv/bin/dho acquire run
```

**Check: CH2 remains a clock; only CH3 returns Low.**

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s33-disabled-raw10k" \
  --condition "/OE=disabled; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --channel-items 3=vavg,vmax,vmin,vpp \
  --mode raw --points 10000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s33-disabled-raw10k.zip"
```

CH2 records frequency, levels, peaks and rise/fall. Disabled CH3 requests Vavg/Vmax/Vmin/Vpp, not frequency. A `null` is unavailable, not zero; inspect its reason. Malformed responses, SCPI and communication errors mean failure.

<a id="analysis"></a>
## 7. Offline analysis

No scope connection is needed here. Preserve original ZIPs.

1. Analyze enabled operation.

```bash
.venv/bin/dho analyze-session "captures/input-buffer/$IBUF_RUN/sessions/s32-enabled-raw10k.zip" \
  --from-channel 2 --to-channel 3 \
  --markdown "captures/input-buffer/$IBUF_RUN/analysis/s32-enabled-raw10k.md" \
  --json "captures/input-buffer/$IBUF_RUN/analysis/s32-enabled-raw10k.json"
```

2. Analyze disabled operation.

```bash
.venv/bin/dho analyze-session "captures/input-buffer/$IBUF_RUN/sessions/s33-disabled-raw10k.zip" \
  --from-channel 2 --to-channel 3 \
  --markdown "captures/input-buffer/$IBUF_RUN/analysis/s33-disabled-raw10k.md" \
  --json "captures/input-buffer/$IBUF_RUN/analysis/s33-disabled-raw10k.json"
```

3. Open Markdown reports and compare with images/instrument readings.

```bash
open "captures/input-buffer/$IBUF_RUN/analysis/s32-enabled-raw10k.md"
```

```bash
open "captures/input-buffer/$IBUF_RUN/analysis/s33-disabled-raw10k.md"
```

Use an editor if there is no suitable default app.

- Start with non-inversion, frequency, High/Low and Vmax/Vmin. There is no automatic pass/fail.
- Disabled output may yield `STATIC_SIGNAL` / `PROPAGATION_UNAVAILABLE`; verify actual waveforms/voltages before accepting it. Noise can produce spurious frequency estimates.
- Estimated High/Low uses the lowest/highest 10% of samples, unlike the instrument's VTOP/VBASE algorithm.
- Analysis rise/fall uses 10–90%; do not substitute it for the LCX541 0.8–2.0 V slew requirement.
- Delay includes probe skew and wiring differences. Record sample interval, bandwidth, measurement thresholds and deskew; uncorrected estimates cannot establish datasheet compliance.
- MAIN instrument values and partial RAW CSV analysis can cover different intervals. Manifest timestamps identify export time, not hardware acquisition time.

<a id="larger"></a>
## 8. Optional larger RAW captures

Not required initially. After small RAW succeeds, use these for transfer-time or longer-record checks with the same wiring and output enabled. This is not a higher-frequency source test.

### 8-1. 100,000 points

Enable the switch first.

```bash
.venv/bin/dho config acquisition --type NORM --memory-depth 100k --area MAIN
```

```bash
.venv/bin/dho acquire run
```

**Check:** settings, waveform and sample rate. Record transfer elapsed seconds.

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s40-enabled-raw100k" \
  --condition "/OE=enabled; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --channel-items 3=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --mode raw --points 100000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s40-enabled-raw100k.zip"
```

### 8-2. 1,000,000 points

Only after the smaller transfer succeeds:

```bash
.venv/bin/dho config acquisition --type NORM --memory-depth 1M --area MAIN
```

```bash
.venv/bin/dho acquire run
```

**Check: the waveform has been freshly acquired.**

```bash
.venv/bin/dho --timeout 120 session --channels 2 3 \
  --point 2=TP_A1 \
  --point 3=TP_Y1 \
  --stage baseline --condition "case=s41-enabled-raw1m" \
  --condition "/OE=enabled; nominal=2.7MHz" --condition "probe=10X; coupling=DC" \
  --load buffer-standalone \
  --channel-items 2=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --channel-items 3=frequency,high,low,vmax,vmin,vpp,rise,fall \
  --mode raw --points 1000000 --chunk-points 1000 \
  --output "captures/input-buffer/$IBUF_RUN/sessions/s41-enabled-raw1m.zip"
```

`--timeout 120` is a communication timeout, not a guarantee of total completion within 120 seconds. Check progress and actual duration. Analyze as above with matching source/output IDs. More points alone do not improve coarse sample spacing.

<a id="finish"></a>
## 9. Finish, resume and publish

### Finish

1. Open the switch to disable output.
2. Stop the scope.

```bash
.venv/bin/dho acquire stop
```

3. Disconnect Nano USB power before removing probes/wiring. Do not assume the SRAM image survives.
4. Fill the record template using confirmed / needs remeasurement / not performed. Include wiring length, supply, probes, GND, switch state, warnings and stop reasons. Store original photos in `photos/`.
5. Clear the connection variable.

```bash
unset DHO_HOST
```

<a id="resume"></a>
### Resume the same run

A new Bash does not retain variables. Verify the run ID; for a new run return to [folder creation](#folders).

```bash
cd "$HOME/git/ps1-spdif-fpga"
```

```bash
IBUF_RUN=ibuf-001
```

```bash
test -d "captures/input-buffer/$IBUF_RUN/sessions"
```

Repeat connection/physical checks and dynamic-image programming. Do not overwrite ZIPs: append `-r02` to both the `case` and filename for repeated captures, and use matching analysis names. This procedure does not use `--force`.

<a id="review"></a>
### Local review and publication

Inspect a ZIP locally. The example uses enabled RAW; substitute `s10-static-low` to check the first static capture.

```bash
unzip -l "captures/input-buffer/$IBUF_RUN/sessions/s32-enabled-raw10k.zip"
```

```bash
mkdir -p "captures/input-buffer/$IBUF_RUN/review/s32-enabled-raw10k"
```

```bash
unzip -n "captures/input-buffer/$IBUF_RUN/sessions/s32-enabled-raw10k.zip" -d "captures/input-buffer/$IBUF_RUN/review/s32-enabled-raw10k"
```

```bash
open "captures/input-buffer/$IBUF_RUN/review/s32-enabled-raw10k/screen.png"
```

Open `ch2.csv`, `ch3.csv` and `manifest.json` in an editor. Single-channel source captures have no `ch3.csv`. Verify point counts, time axes, amplitudes and agreement with scope readings/screens. Extract only ZIPs generated by this procedure, not untrusted externally supplied archives.

**The next steps require publication review and user authorization of the selected content and scope.** Inspect originals, photos and analysis MD/JSON for IPs, serials, personal information, absolute paths, metadata and comments. Notes are not anonymized automatically. Do not publish material you cannot inspect.

```bash
mkdir -p "docs/evidence/input-buffer/$IBUF_RUN"
```

Example: copy only a PNG whose content and metadata have been reviewed; preserve the local original.

```bash
cp -n "captures/input-buffer/$IBUF_RUN/review/s32-enabled-raw10k/screen.png" "docs/evidence/input-buffer/$IBUF_RUN/enabled.png"
```

Create a Japanese `README.md` and, when possible, `README.en.md` based on the [record template](templates/input-buffer-record.en.md), adjusting language links and retaining unknowns. Link them from the [evidence index](evidence/input-buffer/README.en.md). Raw ZIPs/full CSVs require separate necessity, size and disclosure review; do not copy them automatically.

```bash
git status --short
```

Committing/pushing is outside this measurement procedure; use the usual diff, privacy and per-push approval process. Do not use `git add -f captures`. Git-ignored originals need a separate local backup.

<a id="validation"></a>
## Validation and tool changes

- Reviewed the 0.3.0 README, CLI and `session.py` / `files.py` / `analyze.py`. Destination paths are configurable via `--output`, `--markdown` and `--json`; parent directories must exist.
- **No destination-related tool change or change-request prompt is needed.** The tool checkout is not modified. OS/execution-environment write permissions are separate from tool capability.
- 2026-09-13: checked shell syntax and CLI arguments for 81 command blocks per language, matching bilingual CLI recipes, and 111 related local links/anchors. Mock checks exercised all 11 capture commands (up to 1 million points), both analysis commands, relative/absolute destinations in a different working directory, ZIP contents and point counts. All 49 existing tool tests passed. Mock data was kept only in temporary storage, never registered as real project evidence.
- Scope communication, real settings application, Gowin programming, circuit voltages/waveforms and public measurement evidence remain unperformed.
