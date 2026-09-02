# Sources and licensing

This repository contains an original implementation and does not copy RTL from
the projects below.

## puhitaku / YOTSUHACK `nintendo-switch-i2s-to-spdif`

- Source: https://github.com/puhitaku/nintendo-switch-i2s-to-spdif
- Consulted for the proven high-level pipeline: serial PCM receiver, dual-clock
  FIFO, IEC 60958 framing, and S/PDIF output.
- Repository-level code is MIT licensed (Takumi Sueda, 2020).
- Its `src/spdif/*.v` files are derived from Ultra-Embedded and explicitly
  licensed GPL version 2 or later. Those files are **not included or copied**.
- This project's `spdif_tx.v` is a new implementation from the IEC 60958 frame
  structure, so this repository is distributed under MIT.

## Sipeed Tang Nano 9K official material

- Board page: https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K
- Official examples: https://github.com/sipeed/TangNano-9K-example
- Schematic revision 3672:
  https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf

The device identifier and board pin constraints were checked against these
official sources. No Sipeed example source is included.
