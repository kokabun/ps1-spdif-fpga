# PS1 Parallel I/O接続型S/PDIFドングルの設計検討

[English translation](parallel-io-dongle.en.md) · [README](../README.md)

調査日：2026-09-03。日本語版を正本とし、競合時は日本語版を優先します。

**設計検討であり、施工手順や実機動作保証ではありません。** 本変更はドキュメントのみで、
既存のPU-20直接接続PoC、RTL、PLL、ピン制約は変更しません。ジャンパ1本案は未検証です。
電圧・電源・導通に不明点がある場合は接続を停止し、測定結果をもとに判断してください。

## 根拠の区分

「一次確認」は製作者自身の製品説明で確認できる範囲を指します。Sonyの仕様保証とは異なります。
コミュニティのピン表はSony一次資料へ格上げせず、第三者解析として扱います。

| 区分 | 確認内容 | 根拠・限界 |
|---|---|---|
| 一次確認：製作者説明 | TheRetroChannel方式はParallel I/Oへ接続し、光・同軸S/PDIFを出力する。既存信号に加え、不足する2信号を空いている2端子へ内部ジャンパする | [製品ページ][trc]。本文は信号名と31/65の割当を明示していない。公式回路図は今回未確認 |
| 一次確認：製作者説明 | PSIOはParallel I/Oを占有する。TheRetroChannelはPSIO改造機との非互換も明記 | [PSIO公式ガイド][psio]、[TheRetroChannel][trc] |
| 第三者解析 | PIOにはSYSCLK1、BCLK、LRCLK、SDIN、電源、GNDが既存配線され、未改造機の31/65はNCと報告される | [PCSX-Redux][pio]、[PSX-SPX][pinouts]。基板revision・既存改造の確認が必要 |
| 第三者実装解析の報告 | TheRetroChannel方式の追加線はPin 31=DOUT、Pin 65=MCLKとされる | [第三者解析記事][analysis]。今回は検索索引の抜粋を確認し、本文全体の再取得には失敗。製作者公式回路図による一次確認でも、本プロジェクトでの追試でもない |
| 第三者ピン資料 | CXD2925QのDATOはPin 99 | [PSX-SPXのCXD2925Qピン表][pinouts]。Sony一次回路図との照合・対象PU-20での導通確認は未完了 |
| 仮説 | SYSCLK1を利用し、DATO/DOUT→PIO Pin 31の内部ジャンパ1本でFPGA版を構成する | 下記の条件付き提案。実装・実機検証は未実施 |

第三者記事中の他基板向けDAC端子番号をPU-20へ転用しません。本書のDOUTは追加する
シリアルPCM出力線の呼称であり、PIOデータバスのD0〜D15やSDINとは別です。

## PIO信号と候補割当

番号はFPGA端子番号ではなく**PS1の68極PIO端子番号**です。console背面・基板側・
ドングル側では見え方が反転するため、資料の視点と現物の向きを照合します。

| PIO Pin | 報告されている信号 | ドングル案 |
|---|---|---|
| 31 | 未改造機ではNC | CXD2925Q Pin 99 DATOから追加するDOUT入力候補 |
| 65 | 未改造機ではNC | 第三者解析では追加MCLK。1本案では追加せず未使用 |
| 32 | SYSCLK1（PSX-SPXではSYSCK表記） | 33.8688 MHzと報告される基準クロック候補 |
| 33 | BCLK | PCM受信用クロック候補 |
| 66 | LRCLK（LRCK） | PCM受信用左右境界候補 |
| 67 | SDIN：PS1への音声入力 | Phase 1/2では駆動しない。将来の入力拡張候補 |
| 17 / 51 | 3.3 V表記の電源。別資料は3.5 V表記 | 外付けドングル給電候補。許容電圧・電流は未確定 |
| 1 / 35、34 / 68等 | GND | 電源リターン候補。導通・電流経路を確認 |

割当の根拠は[PCSX-Redux][pio]および[PSX-SPX][pinouts]です。名称が似ていても、
PIO BCLK/LRCLKとSPU出力BCKO/LRCOが同じネット・位相とは断定しません。
PIO音声系は外部入力用とも説明されており、追加DATOとのタイミング整合が検証の中心です。

## 内部ジャンパ1本案とクロック条件

```text
PU-20内部（追加配線候補）
  CXD2925Q Pin 99 DATO ──ジャンパ1本── PIO Pin 31

PIO ── 電圧・信号品質確認／必要な保護・変換 ── FPGAドングル
  Pin 31 DOUT ──────────────────────────── PCM RX
  Pin 33 BCLK / Pin 66 LRCLK ───────────── PCM RX
  Pin 32 SYSCLK1 ──────────────────────── クロック処理
                                              ↓
                                      FIFO → S/PDIF → PLT133/T10W
  Pin 65：MCLKを追加しない案
```

33.8688 MHzと44.1 kHzが正確に同期する場合、SYSCLK1は768Fsになります。

- `33.8688 MHz / 6 = 5.6448 MHz = 128Fs`：BMC half-bit更新周期の候補。
- または`33.8688 MHz / 2 = 16.9344 MHz = 384Fs`として既存coreへ供給する案。

これは周波数の計算であり、実機での同期・位相・ジッタの証明ではありません。
SYSCLK1をWCKO/MCLKと同一信号とは扱いません。
既存[`spdif_tx.v`](../rtl/spdif_tx.v)は384Fsを3分周するので、33.8688 MHzを
無変更で投入すると送信速度が2倍になります。Phase 2では分周比の対応、または
platform側の適切なクロック回路と制約が必要です。今回はどちらも実装しません。
単純な論理分周を安全なクロック配線とみなさず、Gowinのクロック資源とタイミング解析を確認します。

必要条件は、SYSCLK1と音声Fsの比が安定すること、PIO BCLK/LRCLKで追加DATOを正しく
受信できること、FIFOが継続的にoverflow/underflowしないことです。FIFOだけでは
独立クロック間の継続的な周波数差を解消できません。

## 給電・信号保護・実機確認

Pin 17/51は給電候補ですが、**3.3 V固定とも、Tang Nano 9Kや専用PCBを直接給電できるとも未確定**です。
資料間の3.3/3.5 V表記差は実測と対象基板の電源仕様で解決します。

- 無負荷・負荷時電圧、リップル、起動時変動、電源系統の供給余力、コネクタ定格。
- FPGA core/I/O電源、レギュレータ、光送信器、将来のRXを含む定常・最大・突入電流。
- 逆流、USBとの二重給電、未給電I/Oへの信号流入、電源投入順序、保護回路。
- 各信号のhigh/low、overshoot、負荷、配線長、バッファの必要性。電源電圧とI/O耐圧は別に確認。
- 電源を切った状態でPin 31/65のNC・既存改造を確認。通電中の抜き差しは前提にしない。
- オシロスコープでSYSCLK1、BCLK、LRCLK、DATOを観測し、周波数比、エッジ、
  セットアップ／ホールド、RJのビット位置、左右極性を確認。開発時使用機はDHO914S。
- 起動、リセット、無音、ゲーム音、CD音声などで同期とデータを検証し、既知の左右別PCMと
  復号結果を比較する。机上の分周計算だけで動作確認完了としない。

破損につながる電圧・出力競合・電源条件の不確定事項が残る場合は、配線や通電を進めません。

## SDINを使う将来の入力拡張

Pin 67を使い、S/PDIF RX→PCM→PS1音声入力へ拡張する構想を残します。
[PCSX-Redux][pio]はPS1がBCLK/LRCLKを出力し、SDINへ音声を受けると説明しています。
ただし、入力形式を現在のDATO用16-bit RJ受信と同じと決めつけません。
外部S/PDIFの回復クロックとPS1のクロックは非同期になり得るため、対応レート、
クロックドメイン越え、必要に応じたサンプルレート変換、無信号時ミュート、
SPU外部入力の有効化・音量設定、他ドライバとの競合を別途検討します。RX RTLは未実装です。

## PSIOとの競合

[PSIO公式ガイド][psio]が示すとおり同じParallel I/Oを使用するため、直挿しは物理的に競合します。
さらに[PSX-SPX][pinouts]ではSwitch Boardが31/65を/IRQ2・/CS5用途へ転用すると報告されています。
PSIOカートリッジを外すだけで元のNCに戻るとは限りません。単純な分岐やパススルーによる
共存を提案せず、PSIO改造機は本案の検証対象から除外します。

## 段階的な検証計画

| 段階 | 対象 | 次段階へ進む条件 |
|---|---|---|
| Phase 1 | PU-20→Tang Nano 9K→PLT133/T10Wの既存PoC | 安全な電圧・配線、PCM抽出、S/PDIF復号と光受信を実機確認。現状は限定的なRTLテストのみ |
| Phase 2 | Pin 31へDOUT追加＋既存PIOクロック／音声信号 | 電源仕様、SYSCLK1同期、PIO音声クロックとDATOの整合、長時間のFIFO動作を検証。Pin 65は追加しない仮説 |
| Phase 3 | GW1NZ-1等を搭載した専用Parallel I/OドングルPCB | Phase 2の結果を反映し、電源・I/O耐圧・クロック・資源量・コネクタ／筐体・保護回路を確定 |

## 出典

- [TheRetroChannel製品説明][trc]：製作者による接続方式と2線追加の説明。公式回路図とは区別。
- [PSIO公式Quick Start Guide][psio]：Parallel I/Oへの接続を確認。
- [PCSX-Redux PIO port][pio]：コミュニティによるPIO解析。Sony公式仕様書ではない。
- [PSX-SPX Pinouts][pinouts]：コミュニティ資料。電源表記差、NC転用、CXD2925Q端子を確認。
- [第三者解析記事][analysis]：31=DOUT、65=MCLKという報告の参照先。今回の本文取得は未完了。

[trc]: https://lectronz.com/products/playstation-ps1-digital-audio-adaptor
[psio]: https://ps-io.com/support/PSIO%20Quick%20Start%20-%2025C18%20R11.pdf
[pio]: https://github.com/grumpycoders/pcsx-redux/wiki/PIO-port
[pinouts]: https://psx-spx.consoledev.net/pinouts/
[analysis]: https://strefapsx.pl/forum/nasze-mody/cyfrowe-audio-z-ps1-moje-znaleziska/
