# Direct SPU PoC: provisional circuit and Akizuki parts

[日本語](spu-direct-build.md) / [README](../README.en.md) / [Timing validation](timing-validation.en.md)

Japanese is authoritative. Rev.A. PS1 voltages and waveforms are unmeasured: **the SPU interface is not released for wiring**. This procurement plan does not place an order.

![Provisional direct SPU circuit](spu-direct-circuit.svg)

The upper section is an unresolved interface; the lower section is a proposed optical circuit. The editable SVG is not an EDA schematic, PCB layout or physical pin-view drawing. No ERC or fabrication data is supplied.

## Prototyping-board placement

![Optical-board component and wiring concept](spu-direct-layout.svg)

The [scalable SVG placement drawing](spu-direct-layout.svg) assumes the preferred AE-3G 72×47.5mm board. It is conceptual and does not assign hole coordinates. Put U1 at an edge with the optical connector facing outward, J1 and JP1 at the opposite side, C1 immediately across U1 Vcc–GND, C2 near the power entry, and R1 across Vin–GND.

Use four labeled test points:

| Test point | Net | Measurement |
|---|---|---|
| TP1 | 3V3 | Unloaded and active voltage and supply variation |
| TP2 | GND | Reference for all measurements; keep it close to TP4 for a short probe ground |
| TP3 | SPDIF_SRC | FPGA side of JP1 |
| TP4 | SPDIF_VIN | Loaded U1 side of JP1 |

The drawing shows the component view and a see-through solder-side convention. The physical underside reverses left and right, so do not transfer hole positions directly. Treat the net table as authoritative, leave unused holes between signals and avoid crossing bare conductors. Once the exact board is selected, replace this with a hole-numbered drawing based on its dimensions, mounting holes, U1 support pins and J1 orientation.

### Akizuki prototyping-board candidates

The preferred board is **AE-3G**. Its C size leaves room for first-time wiring and test points. Its plated through holes aid inspection from either side, and its 1.6mm FR-4 thickness matches the board thickness in the PLT133/T10W manufacturer's layout example. Matching thickness does not establish support-tab fit.

| Priority | Akizuki product | Specification | Assessment |
|---|---|---|---|
| Preferred | [100189 AE-3G plated-through FR-4 C board](https://akizukidenshi.com/catalog/g/g100189/) | 72×47.5×1.6mm, 2.54mm pitch, 1mm holes, 3.2mm mounting holes | Best room for wiring and measurement; assumed by this drawing |
| Alternative | [103231 plated-through CEM-3 C board](https://akizukidenshi.com/catalog/g/g103231/) | 72×47mm, 2.54mm pitch | Same general size; check the current dimension drawing |
| Compact option | [108241 AE-D1 single-sided D board](https://akizukidenshi.com/catalog/g/g108241/) | 47×36×1.6mm, 2.54mm pitch, 1mm holes | May fit the circuit, but leaves less room for first-time probing, mounting and wiring |

Prefer isolated pads for this first build; pre-connected grid or power-rail boards add track-cut verification. Buying **two AE-3G boards** is recommended so one can serve for machining practice or recovery. PLT electrical pins are specified as 0.5mm wide, but support tabs have not been confirmed to fit the board's 1mm round holes. Test-fit before soldering; machine holes/slots to the manufacturer's dimensions if required, rather than bending terminals to force a fit.

## Parts for one optical board

Tang Nano 9K and its USB cable are assumed to be on hand. Verify current stock and pack sizes before purchasing.

| Reference | Akizuki product | Used / suggested purchase | Purpose |
|---|---|---|---|
| PCB | [100189 AE-3G plated-through FR-4 C board](https://akizukidenshi.com/catalog/g/g100189/) | 1 / **2 recommended** | 72×47.5×1.6mm, isolated 2.54mm pads; assumed by the placement drawing; test-fit U1 support tabs |
| U1 | [109598 PLT133/T10W](https://akizukidenshi.com/catalog/g/g109598/) | 1 / 1 | Optical transmitter with driver |
| C1 | [113582 0.1µF50V X7R, 2.54mm](https://akizukidenshi.com/catalog/g/g113582/) | 1 / pack of 10 | RDER71H104K0P1H03B, leaded decoupling capacitor |
| C2 | [117897 10µF50V Rubycon PX](https://akizukidenshi.com/catalog/g/g117897/) | 0–1 / 1 | Optional bulk capacitor, positive to 3V3 |
| R1 | [125103 1/4W 10kΩ](https://akizukidenshi.com/catalog/g/g125103/) | 1 / bag of 100 | Proposed Vin pull-down |
| J1 / JP1 | [100167 1×40 header](https://akizukidenshi.com/catalog/g/g100167/) | 3+2 pins / 1 strip | Cut to length; leftovers can serve as test pins |
| JP1 shunt | [103890 handled 2.54mm jumper](https://akizukidenshi.com/catalog/g/g103890/) | 1 / pack of 20 | Initially removed; operate with power off |
| Wiring option | [103475 female–female 15cm black](https://akizukidenshi.com/catalog/g/g103475/) | As needed / 1 set | Temporary connections where both boards have male headers |
| Wiring option | [103476 female–female 15cm blue](https://akizukidenshi.com/catalog/g/g103476/) | As needed / 1 set | Label both ends. 15cm is not a validated high-speed wiring length |
| Recommended test points | [107591 TEST-1(BK)](https://akizukidenshi.com/catalog/g/g107591/) | 4 / pack of 10 | TP1=3V3, TP2=GND, TP3=SPDIF_SRC, TP4=SPDIF_VIN; header pins can substitute |
| Mounting candidate | [107566 M3 10mm nylon spacer](https://akizukidenshi.com/catalog/g/g107566/) | 4 / 4 | Only if board holes fit; select screws/nuts later |
| Optional tuning stock | [103941 1/4W 33Ω](https://akizukidenshi.com/catalog/g/g103941/) | 0 / bag of 100 if needed | Not fitted in this circuit; possible source-series resistor near FPGA, subject to waveform testing |

Use existing equivalent parts where possible. C1 uses only one capacitor despite its ten-piece pack. Do not confuse it with SMD or Y5V parts.

Hold purchases of PS1 level translators, buffers, protection and their supplies until measurements. Do not assume generic bidirectional I²C converters suit audio clocks. Select fine SPU wires, connectors and strain relief after inspecting the board; the listed jumpers are not intended for direct attachment to IC legs. Select screws and nuts for AE-3G's 3.2mm mounting holes and the final installation; these are separate from any machining needed for the PLT support tabs.

A square TOSLINK cable and optical-input DAC/amplifier supporting 44.1kHz stereo PCM are needed, but suitable Akizuki products were not verified in this search. Use existing equipment or another supplier. An optical receiver component alone is not a DAC. Check existing soldering tools and a multimeter separately. No separate external 3.3V supply is proposed.

## Tang Nano 9K breadboard PoC

First verify Nano programming, its output pin and voltage without connecting the PS1. Then connect the optical-transmitter board. Mount Nano on an insulated support and use short jumper wires from its fitted male headers to the breadboard.
If inserting Nano directly into a breadboard, verify header spacing, available holes and clearance from underside components on the actual hardware. This section is not a hole-numbered assembly drawing.

![Corrected Tang Nano 9K breadboard PoC circuit](spu-direct-breadboard.svg)

[Scalable corrected SVG](spu-direct-breadboard.svg). It was redrawn from the authoritative current net table, keeping Nano 3V3 separate from USB 5V.
C1/C2 are between U1 Vcc and GND, R1 is between SPDIF_VIN and GND, and all four PS1-side signals are explicitly disconnected.

### Additional items

Use these together with the optical-side purchase table. Do not duplicate R1, C1 or C2 on the Nano side.

| Item | Suggested quantity | Purpose and selection |
|---|---:|---|
| Tang Nano 9K and data-capable USB-C cable | 1 each | Use items on hand for power and programming |
| 2.54mm male header | As needed | Only if Nano has no fitted header; populate the required signal and supply pins |
| [Akizuki 100315 EIC-801](https://akizukidenshi.com/catalog/g/g100315/) | 1 | Temporary wiring; verify breaks in the power rails and internal continuity with a meter |
| Female-to-male 2.54mm Dupont jumpers | At least 3 | Nano male header to breadboard for signal, 3V3 and GND; keep them short |
| [Akizuki 100288 breadboard jumper-wire set](https://akizukidenshi.com/catalog/g/g100288/) | 1 set | Point-to-point wiring within the breadboard; different from female-to-male jumpers |
| 33Ω, 1/4W | 0–1 | Optional series resistor; use the tuning stock in the existing table |
| Measurement header/test points | TP-A, TP-B and nearby GND | Additional to TP1–TP4; do not create long stubs |

“Dupont wire” is a common name for jumpers used with 2.54mm headers. Female-to-male connects Nano's male header to the breadboard, male-to-male connects breadboard holes, and female-to-female connects two boards that both have male headers. Match connector gender to the actual hardware. The female-to-female wires in the existing table cannot be inserted directly into breadboard holes.
Label both ends by net instead of relying only on colour. Keep signal and ground close together and wiring short. Measurements must include breadboard and jumper parasitics.

### Output wiring and 33Ω comparison

```text
Nano FPGA29 / J5-9 (spdif_out, LVCMOS33)
  │
  ├─ TP-A (FPGA side of the resistor)
  │
  └─ [shorting jumper or Rs=33Ω] ─ TP-B ─ optical board J1-3 / TP3
      place near Nano output; change only powered off    │ SPDIF_SRC
                                                        JP1 (initially OPEN)
                                                          │ SPDIF_VIN
                                                          ├─ TP4 ─ U1-1 Vin
                                                          └─ R1=10kΩ ─ GND

Nano 3V3 ─ optical board J1-1 / TP1 ─ U1-2 Vcc
Nano GND ─ optical board J1-2 / TP2 ─ U1-3 GND (common ground)
U1-2 ─ C1=0.1µF ─ U1-3 (mandatory, immediately at the pins)
U1-2 ─ C2=10µF  ─ U1-3 (optional, positive to U1-2)
U1-4 / U1-5: NC, leave unconnected
U1 PLT133/T10W ─ TOSLINK ─ optical-input DAC/amplifier
```

FPGA29 is the FPGA package pin and J5-9 is the Nano header position; it does not mean “header pin 29.” The existing CST sets `spdif_out` to pin 29 with LVCMOS33 and DRIVE=8. Power the optical board from Nano **3V3** as designed here; never connect USB 5V to its 3V3 net.
The PLT133/T10W pin numbers, recommended supply range and C1 have been checked against the manufacturer documentation. Do not turn the 5V label in a manufacturer test circuit into a power instruction for this PoC. Confirm the physical pin-view orientation against the datasheet and actual part.

Rs is not fitted in the existing schematic. Begin with a shorting jumper, then replace it with 33Ω only when a comparison is needed. An open circuit with neither resistor nor jumper is not the “zero-ohm” condition.
Place Rs near the Nano output rather than at the end of a long stub. The 33Ω value is not a finalized termination and is not a substitute for level translation, overvoltage protection or a 75Ω coaxial S/PDIF output stage.
TP-B and TP3 share a net but are physically separate. Measure TP4 at the receiver when appropriate. R1=10kΩ is the Vin pull-down after JP1; do not move or duplicate it at TP-A.

### Measurement procedure and records

1. With power off, check for a 3V3-to-GND short, correct header positions, breadboard continuity, U1 orientation and C2 polarity. Keep JP1 OPEN and leave all PS1 inputs disconnected.
2. Program Nano alone and verify the output direction. Do not assume that the current RTL emits valid audio S/PDIF without PS1 inputs. Dynamic comparison requires a separate test source or FPGA configuration that operates with those inputs disconnected.
3. With power off, connect the optical board's 3V3, GND and signal. Measure TP1 relative to TP2 and verify voltage and startup variation. Nano, breadboard and optical board must share ground.
4. After checking the output voltage, close JP1 with power off. Measure TP-A, TP-B, TP3 and TP4 relative to nearby ground. Keep the probe ground short and record High/Low voltage, rise/fall time, overshoot, undershoot and ringing.
5. With power off, replace the shorting jumper with 33Ω and repeat using the same signal, wiring length and probe settings. Check receiver lock and audio only after a valid S/PDIF frame source is available.

Record the FPGA configuration, Rs condition, JP1 state, load, measured 3V3, measurement point, wire length, probe ratio and bandwidth setting. Before programming, power down and return JP1 to OPEN.

### Finalize the PS1 input side after measurement

The existing CST assignments are WCKO (MCLK)=FPGA25/J5-5, BCKO=26/J5-6, LRCO=27/J5-7 and DATO=28/J5-8. They are candidate destinations, not permission to connect the PS1 directly.
Measure PS1 High/Low voltage, frequency, rise/fall time, overshoot, channel polarity, data boundaries and power sequencing before selecting buffers, level translators, protection components and their supplies.
No particular part, including TC74HC4050AP, is selected yet. Confirm PS1-side ground and pickup points on the actual board and do not jumper around the unresolved interface.

The existing SVG files remain the optical-board placement and circuit drawings. This section is authoritative for the additional breadboard PoC wiring.
References checked 2026-09-05: [existing CST](../platform/tang_nano_9k/tang_nano_9k.cst), [official Sipeed schematic](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf), and [Everlight PLT133/T10W Rev.5](https://www.everlighteurope.com/custom/files/datasheets/DPL-0000049.pdf).

## Optical net connections

| Net | Connections |
|---|---|
| 3V3 | J1-1, U1-2, one side of C1, C2 positive if fitted |
| GND | J1-2, U1-3, other side of C1, C2 negative if fitted, one side of R1 |
| SPDIF_SRC | J1-3 from FPGA29 / Nano J5-9, JP1-1 |
| SPDIF_VIN | JP1-2, U1-1, other side of R1 |
| NC | U1-4 and U1-5; do not wire to ground |

J1 numbers are newly defined for this board, not Nano header numbers. Identify Nano 3V3/GND from its schematic and markings. Do not connect PS1 power rails. JP1 disconnects signal only; it is not automatic protection or isolation.

## Rationale and limits

The [Everlight Rev.5 datasheet, pages 2–4](https://www.everlighteurope.com/custom/files/datasheets/DPL-0000049.pdf) specifies the supply range and pin functions and shows 0.1µF decoupling. Place C1 immediately between U1 supply and ground; a remote capacitor is not equivalent.

Sharing Nano's 3.3V supply is a design proposal. The datasheet's 10mA current limit is specified under its stated test conditions including 5V, and does not establish available Nano rail capacity. Check additional load, startup voltage and power sequencing. C2 is optional bulk capacitance, not a manufacturer requirement; keep C1.

R1=10kΩ is a proposed pull-down for an open JP1/high-impedance FPGA output, adding about 0.33mA load at 3.3V High. Check startup behavior and competing internal pull-ups. It is not an automatic guarantee of Low under every configuration.

The manufacturer requires Vin and Vcc to power down together. JP1 defaults OPEN. Before programming, open it with power off. Initially program Nano separately and check output direction/voltage before attaching the optical board or closing JP1 with power off. Do not hot-plug.

## Completing the SPU interface

CXD2925Q pins 97/98/99/100 are candidates from [third-party pin information](https://psx-spx.consoledev.net/pinouts/), not confirmed here by Sony documentation or continuity testing. Establish safe PU-20 pickup points and ground without working on its mains power board. Measure voltage, clocks, edges, polarity and RJ boundaries before soldering signal leads. Then select the interface, wiring and constraints; no pre-measurement bypass is specified.

Nano pins follow the [existing CST](../platform/tang_nano_9k/tang_nano_9k.cst) and [official Sipeed schematic](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf). Clock routing still requires place-and-route verification. Before powering the optical board, check polarity, physical pin orientation, shorts, NC pins and open JP1. Optical-board testing does not authorize connection to an unmeasured PS1.
