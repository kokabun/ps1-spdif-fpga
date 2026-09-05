# Direct SPU PoC: provisional circuit and Akizuki parts

[日本語](spu-direct-build.md) / [README](../README.en.md) / [Timing validation](timing-validation.en.md)

Japanese is authoritative. Rev.A. PS1 voltages and waveforms are unmeasured: **the SPU interface is not released for wiring**. This procurement plan does not place an order.

![Provisional direct SPU circuit](spu-direct-circuit.svg)

The upper section is an unresolved interface; the lower section is a proposed optical circuit. The editable SVG is not an EDA schematic, PCB layout or physical pin-view drawing. No ERC or fabrication data is supplied.

## Parts for one optical board

Tang Nano 9K, its USB cable and a separately selected prototyping board are assumed. Verify current stock and pack sizes before purchasing.

| Reference | Akizuki product | Used / suggested purchase | Purpose |
|---|---|---|---|
| U1 | [109598 PLT133/T10W](https://akizukidenshi.com/catalog/g/g109598/) | 1 / 1 | Optical transmitter with driver |
| C1 | [113582 0.1µF50V X7R, 2.54mm](https://akizukidenshi.com/catalog/g/g113582/) | 1 / pack of 10 | RDER71H104K0P1H03B, leaded decoupling capacitor |
| C2 | [117897 10µF50V Rubycon PX](https://akizukidenshi.com/catalog/g/g117897/) | 0–1 / 1 | Optional bulk capacitor, positive to 3V3 |
| R1 | [125103 1/4W 10kΩ](https://akizukidenshi.com/catalog/g/g125103/) | 1 / bag of 100 | Proposed Vin pull-down |
| J1 / JP1 | [100167 1×40 header](https://akizukidenshi.com/catalog/g/g100167/) | 3+2 pins / 1 strip | Cut to length; leftovers can serve as test pins |
| JP1 shunt | [103890 handled 2.54mm jumper](https://akizukidenshi.com/catalog/g/g103890/) | 1 / pack of 20 | Initially removed; operate with power off |
| Wiring option | [103475 female–female 15cm black](https://akizukidenshi.com/catalog/g/g103475/) | As needed / 1 set | Temporary connections where both boards have male headers |
| Wiring option | [103476 female–female 15cm blue](https://akizukidenshi.com/catalog/g/g103476/) | As needed / 1 set | Label both ends. 15cm is not a validated high-speed wiring length |
| Optional test points | [107591 TEST-1(BK)](https://akizukidenshi.com/catalog/g/g107591/) | 3 / pack of 10 | Label 3V3, GND, Vin; header pins can substitute |
| Mounting candidate | [107566 M3 10mm nylon spacer](https://akizukidenshi.com/catalog/g/g107566/) | 4 / 4 | Only if board holes fit; select screws/nuts later |
| Optional tuning stock | [103941 1/4W 33Ω](https://akizukidenshi.com/catalog/g/g103941/) | 0 / bag of 100 if needed | Not fitted in this circuit; possible source-series resistor near FPGA, subject to waveform testing |

Use existing equivalent parts where possible. C1 uses only one capacitor despite its ten-piece pack. Do not confuse it with SMD or Y5V parts.

Hold purchases of PS1 level translators, buffers, protection and their supplies until measurements. Do not assume generic bidirectional I²C converters suit audio clocks. Select fine SPU wires, connectors and strain relief after inspecting the board; the listed jumpers are not intended for direct attachment to IC legs. Select the prototyping board, screws and nuts together, checking the PLT outline and support pins as well as signal pitch.

A square TOSLINK cable and optical-input DAC/amplifier supporting 44.1kHz stereo PCM are needed, but suitable Akizuki products were not verified in this search. Use existing equipment or another supplier. An optical receiver component alone is not a DAC. Check existing soldering tools and a multimeter separately. No separate external 3.3V supply is proposed.

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
