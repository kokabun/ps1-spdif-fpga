# PS1 S/PDIF FPGA PoC

> 実施順序（2026-09-04）：[SPU直結からPIOへ移行する計画](docs/direct-to-pio-plan.md)を参照してください。まずPIOを使わず直結で検証し、その後にPIOへ移行します。[共通RTL修正と検証結果](docs/rtl-backport.md)を本ブランチへ反映しました。実機は未検証です。

[English translation / 英訳](README.en.md)

[SPU直結の暫定回路図・秋月購入リスト](docs/spu-direct-build.md)を追加しました。PS1側は未測定・施工不可です。

以下の構成を対象とする概念実証（PoC）です。

```text
SCPH-7000 / PU-20 (CXD2925Q)
        -> Tang Nano 9K (GW1NR-9)
        -> IEC 60958 / S/PDIF
        -> 秋月電子 109598 (Everlight PLT133/T10W)
```

**まだPlayStationをFPGAへ接続しないでください。** CXD2925Qの信号電圧、
サンプリングエッジ、LRCK極性、スロット長、Right-Justifiedの正確な境界を、
実機のPU-20で先に測定する必要があります。誤った電圧を接続すると、どちらの
基板も恒久的に破損する可能性があります。本リポジトリでは、これらの未確認
事項を推測で固定していません。

## 現在の実装状況

将来構想は[Parallel I/O接続型S/PDIFドングルの設計検討](docs/parallel-io-dongle.md)を参照してください。
一次資料・第三者の報告・未検証の仮説を分けて整理しています。PIO対応は未実装です。

- 移植可能な16-bit Right-Justified PCM receiver
- 移植可能な4エントリ asynchronous FIFO
- IEC 60958 consumer stereo frame generatorおよびBMC出力
- 想定される`384*Fs` WCKOから`128*Fs`への正確なclock-enable分周
- Tang Nano 9K用top、device選択、pin constraints
- 自己検証を行うreceiverおよびtransmitter testbench
- [GW1N-1](platform/tang_nano_gw1n1/README.md)および[GW1NZ-1](platform/tang_nano_1k_gw1nz1/README.md)向けplatformディレクトリの雛形

9K platformはWCKOを直接使用するため、PLLをインスタンス化しません。WCKOが
16.9344 MHz（`384 * 44.1 kHz`）であると確認できれば、WCKO 3周期ごとのpulseが
5.6448 MHzのBMC half-bit rateと正確に一致します。`audio_clock.v`はplatform固有の
wrapperとして分離しているため、測定結果に応じてcoreを変更せずgenerated rPLLへ
置き換えられます。

## 設計

```text
BCKO/LRCO/DATO -> Right-Justified RX --write--> asynchronous FIFO
                                                       |
WCKO -> platform audio_clock -> IEC 60958 + BMC <------read
                                      |
                                  PLT133/T10W
```

receiverは各LRCK slotで最後にsamplingした16 bitを保持します。`LRCK_LEFT`と
`SAMPLE_ON_NEGEDGE` parameterを公開していますが、現在のtop-level設定値は
placeholderであり、CXD2925Qのtimingを確定するものではありません。

transmitterは、channel-status blockごとに192 stereo frame、Z/X/Y preamble、
subframe bit 12〜27の16-bit audio、validity/user/channel-status、even parity、BMCを
出力します。consumer channel-status blockは現在すべて0です。これはconsumer
linear audio、no pre-emphasis、標準の44.1 kHz frequency codeを示します。
professional/copyright/category/word-lengthの詳細化は、このPoCの対象外です。

## PU-20配線候補 — 接続前に測定必須

これまでに確認したreverse-engineering資料から得た作業仮説は次のとおりです。

| CXD2925Q候補 | 機能 | Tang Nano 9K PoC header | FPGA pin |
|---|---|---|---:|
| pin 100 `WCKO` | 16.9344 MHz / 384 Fs想定 | J5-5 | 25 |
| pin 97 `BCKO` | serial bit clock | J5-6 | 26 |
| pin 98 `LRCO` | 44.1 kHz word/channel clock | J5-7 | 27 |
| pin 99 `DATO` | serial PCM | J5-8 | 28 |
| 確認済みのdigital ground | 共通基準電位 | J5 GND | — |

これらのCXD2925Q pin番号とtiming想定は**候補**であり、Sonyのtiming diagramによって
本リポジトリ内で完全に確定したものではありません。対象となるPU-20 revisionで、
ICの向きと導通を確認してください。基板写真だけからpin番号を推定しないでください。

選択したNano 9Kのpin 25〜29はJ5-5〜J5-9へ引き出されており、Sipeed公式回路図では
3.3 V I/O bankに属します。ただし、これはPS1側信号が3.3 V互換であることを証明する
ものではありません。

### オシロスコープでの確認項目

以下の確認にはオシロスコープを使用します。本プロジェクトの開発者が使用する機種は
RIGOL DHO914Sですが、必要な帯域・channel数・測定機能を満たす他の機種でも確認できます。
Nano 9Kと電気的に接続する前に、console側信号をprobeしてください。

1. ground基準と、WCKO、BCKO、LRCO、DATOのDC high/low電圧を確認します。
2. LRCOが約44.1 kHz、WCKOが約16.9344 MHzであることを確認します。
3. BCKO周波数を測定し、LRCOの各half/slotに含まれるBCK cycle数を数えます。
4. 無音ではなく左右非対称のstereo test signalをdecodeします。LRCO極性、MSB/LSB順、
   最後の16-bit位置、dataがBCKO rising/falling edgeのどちらで安定するかを決定します。
5. FPGAのsampling edge候補におけるsetup/hold marginを確認します。
6. 信号levelがGW1NRの3.3 V bank制限を満たす場合だけ、共通groundと短い配線で
   接続します。満たさない場合は、先に適切なlevel shifter/bufferを設計します。
7. 接続後、loading、ringing、overshootによる波形劣化がないか再確認します。
8. S/PDIF出力の半ビットレートが5.6448 MHz（半ビット幅約177.15 ns）であることを確認し、
   receiver lockと左右channelの対応も確認します。実際の遷移回数はデータとプリアンブルに依存します。

測定後、`platform/tang_nano_9k/top.v`の2つのparameterを更新し、
[タイミング制約と波形検証](docs/timing-validation.md)に従ってSDCを完成させてください。
クロック周期だけでなく入力遅延、FIFOのクロックドメイン間経路、resetの確認が必要です。

## PLT133/T10W（秋月電子 109598）

メーカーのRev.5 datasheetでは、推奨電源電圧2.7〜5.5 V、TTL-compatible input
（`VIH >= 2.0 V`、`VIL <= 0.8 V`）、最大16 Mbps、pin機能は1=Vin、2=Vcc、3=GND、
4/5=NCと規定されています。

PoCでは次のように接続します。

```text
Tang Nano J5-9 / FPGA pin 29 (spdif_out) -> PLT133 pin 1 Vin
Tang Nano 3V3                             -> PLT133 pin 2 Vcc
Tang Nano GND                             -> PLT133 pin 3 GND
0.1 uF ceramic capacitorをpin 2とpin 3の直近へ接続
PLT133 pin 4およびpin 5                     -> 未接続
```

datasheetの指示どおり、VinとVccは同時に電源を切ってください。Nano 9KのGPIOへ5 V
logicを入力してはいけません。transmitter inputをfloatingにしないでください
（Vinがfloatingの場合、moduleのLEDが点灯する可能性があります）。

- [秋月電子 商品ページ](https://akizukidenshi.com/catalog/g/g109598/)
- [Everlight datasheet](https://www.everlighteurope.com/custom/files/datasheets/DPL-0000049.pdf)

## simulation

Icarus Verilogをinstallして、次を実行します。

```sh
make test
```

Python 3も必要です。既存単体テストに加え、FIFO容量・満杯・順序・周回・リセットと、
384Fs固定／受信エッジ2種／左右極性2種／16・32-bitスロットの8条件を検証します。
各条件で出力S/PDIFのみを復号し、419組の左右PCM、欠落・重複、音声ビット配置、
パリティ、プリアンブル、ブロック周回、枯渇時の無効フラグと左右ミュートを確認します。
正規化クロックの論理試験であり、実機電圧・同期・Gowin配置配線を保証しません。

各TXクロック周期で半ビット内の出力保持も検査します。半ビット内の後続2周期を
それぞれ壊した波形の拒否と、起動待ち時間を変えた正常波形の受入れを検証します。
クロック周期より短いグリッチや実配線遅延は、このテストの対象外です。

RX testは、末尾16 bitに異なるsampleを格納した32-bit slotを使用します。TX testは
frame request cadence、Z preamble、BMC activityを確認します。hardware-level timingと
光接続の相互運用性については、引き続き上記の実機測定が必要です。

## Gowin EDAでのbuildと書き込み（Tang Nano 9K）

1. Gowin EDAで`platform/tang_nano_9k/ps1_spdif.gprj`を開きます。
2. deviceが`GW1NR-LV9QN88PC6/I5`、top moduleが`top`であることを確認します。
3. [タイミング制約と波形検証](docs/timing-validation.md)に従い、`tang_nano_9k.sdc`の
   クロック・入力遅延・CDC制約を実測と合成後のノード名から確定します。現状は未測定テンプレートです。
4. **Synthesize**、続いて**Place & Route**を実行します。クロック配線資源、入力setup/hold、
   FIFO経路、reset、例外の適用対象を確認します。unconstrained-clock警告の解消だけでは完了しません。
5. Nano 9KのUSB portを接続し、Gowin Programmerを開きます。
6. JTAG chainをscanし、生成された`.fs`を選びます。最初の可逆な試験ではSRAMへの
   programmingを使用してください。内蔵または外部flashは検証後に使用します。
7. consoleへ接続する前に、安全なsynthetic sourceでFPGAと光送信moduleを試験します。

正確なmenu名はGowin EDAのversionによって異なります。driver/license設定については、
[Sipeed Tang Nano 9K公式資料](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K)と
Gowin Software User Guideを参照してください。

## 既知の未確定事項／作業停止条件

- 対象PU-20におけるCXD2925Qの出力電圧とdrive能力
- BCKO sampling edgeとDATO setup/hold timing
- LRCO極性と正確なboundary behavior
- slotあたりのBCKO cycle数とsample前のpadding有無
- consoleの各audio stateにおけるWCKO周波数と位相の連続性
- 稼働中のconsole、Nano 9K、光送信module間のpower sequence

どの項目も試行的な配線で解決しないでください。作業を止め、測定し、根拠に基づいて
RTL/constraintsを更新してください。PS1のhigh levelがNano 9Kのbank定格を超える場合や、
overshootがabsolute maximumを超える場合は、level translatorが必須です。

## 参考資料とlicense

本リポジトリの独自実装はMIT licenseです。architectureの検討では、動作実績のある
[puhitaku/YOTSUHACKのTang Nano実装](https://github.com/puhitaku/nintendo-switch-i2s-to-spdif)
を参照しました。同リポジトリ全体はMITですが、Ultra-Embedded由来のS/PDIF RTLは
GPL-2.0-or-laterです。本リポジトリにはそのRTLをコピーしていません。正確な出典、
license、Sipeed公式資料については[`THIRD_PARTY.md`](THIRD_PARTY.md)を参照してください。

内容が競合する場合は、この日本語版を正本として優先します。
