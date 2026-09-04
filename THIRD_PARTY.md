# 出典とライセンス

[English](THIRD_PARTY.en.md) / [README](README.md)

日本語を正本とする。本リポジトリは独自実装を含み、以下のプロジェクトからRTLをコピーしていません。

## puhitaku / YOTSUHACK `nintendo-switch-i2s-to-spdif`

- [ソース](https://github.com/puhitaku/nintendo-switch-i2s-to-spdif)
- 動作実績のあるserial PCM receiver、dual-clock FIFO、IEC 60958フレーム生成、S/PDIF出力という全体構成を参考にしました。
- リポジトリ上位のライセンスはMIT（Takumi Sueda、2020年）です。
- `src/spdif/*.v`はUltra-Embedded由来で、GPL version 2以降が明記されています。これらのファイルは**同梱もコピーもしていません**。
- 本プロジェクトの`spdif_tx.v`はIEC 60958のフレーム構造から新規実装しており、本リポジトリはMITで配布します。

## Sipeed Tang Nano 9K公式資料

- ボード資料: https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K
- 公式サンプル: https://github.com/sipeed/TangNano-9K-example
- 回路図（ファイル名3672）:
  https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf

device識別子とボードの端子制約は、これらの公式資料に照合しました。
Sipeedサンプルのソースは同梱していません。照合はGowin配置配線や実機動作の検証を意味しません。
