# DHO914S CLIによる入力バッファ単体試験と記録

[English](input-buffer-measurement.en.md) / [試験概要・回路](input-buffer-test.md) / [公開エビデンス](evidence/input-buffer/README.md)

2026-09-13作成。日本語を正本とする。**実機未実施の手順書**。PS1も光送信モジュールも接続せず、LCX541出力をFPGA入力へ戻さない。

## 目次

- [0. 最初に確認すること](#before)
- [1. PC環境を用意する](#setup)
- [2. 今回の保存先を作る](#folders)
- [3. 接続と設定を確認する](#connect)
- [4. 静的試験を記録する](#static)
- [5. 信号源だけを確認する](#source)
- [6. 入出力を同時に記録する](#dynamic)
- [7. 保存した波形を解析する](#analysis)
- [8. 任意の大きなRAW取得](#larger)
- [9. 終了・再開・公開](#finish)
- [検証範囲・ツール改修の要否](#validation)

<a id="before"></a>
## 0. 最初に確認すること

本書は、[組立・配線・Gowin書込み・電気的な判断条件](input-buffer-test.md)に、PCでの記録操作を付け加える。**上から全コマンドを一括実行しない。1つずつ実行し、各「確認」で止まる。エラーが出たら次へ進まない。** 複数行のコード枠も1コマンドで、行末の `\` を含めてコピーする。

- 配線、IC・変換基板の着脱、プローブ移動はUSB電源OFFで行う。GNDは確認済みの入力基板共通GNDだけ。オシロの保護接地を外さない。
- 電源投入・書込みは `/OE` 無効（OPEN）。USBを抜くとSRAMの試験イメージを失うため、動的試験では再給電ごとに専用イメージを再書込みする。Flash起動の別イメージを試験信号と取り違えない。
- **有効／無効の切替は、回路図のSW_ENABLEを無通電時に配線・固定したスイッチとして用意する前提。** スイッチ開＝無効、閉＝有効。着脱ジャンパJP_EN1だけの場合は、通電中の抜き差しで代用せず切替方法を確認してから進む。CLIは `/OE` を操作しない。
- 配線に自信がない、発熱・電源低下・想定外の電圧がある場合は電源を切り、ここで停止する。
- プローブ補償と両方の10Xを確認する。精密遅延は初回の必須ではない。プローブ間の時間差（skew）が未確認なら「未補正」と記録する。

| オシロ | 測定点 | 現行配置図の穴 |
|---|---|---|
| CH2先端 | TP1＝TP_A1、LCX541 A1入力 | C6 |
| CH3先端 | TP2＝TP_Y1、Rout後の出力 | J17（旧J3ではない） |
| CH2 / CH3のGND | TP3 / TP4、共通GND | D3 / G21 |

穴番号は[配置図](ps1-input-interface.md#ブレッドボード構築イメージ)の前提に合う実物でのみ使用する。信号源だけの試験ではAD1を外してR1〜R3・TP1を残すので、その状態を記録する。

<a id="setup"></a>
## 1. PC環境を用意する

以下はmacOSのBash用。ツールの配置例は本プロジェクトと同じ親フォルダの `rigol-dho914s-tools`。別の場所ならインストール先の指定だけを変える。以降の作業場所は常に **ps1-spdif-fpgaのリポジトリ直下**で、ツール側へ `cd` しない。

1. ターミナルでBashを開始する。

```bash
bash
```

2. 本プロジェクトへ移動する。別の場所へcloneした場合は読み替える。

```bash
cd "$HOME/git/ps1-spdif-fpga"
```

3. Pythonを確認する。本例はツールREADMEと同じ3.14。見つからなければ先にツールREADMEのセットアップを行う。既存の適合環境（Python 3.10以上）があるなら再作成しない。

```bash
python3.14 --version
```

4. **.venvがまだない初回だけ**作成する。既存環境を消したり上書きしたりしない。

```bash
python3.14 -m venv .venv
```

5. このプロジェクトの環境へローカルのツールを導入する。ネットワークが必要なのは依存パッケージ取得時で、測定データの送信ではない。

```bash
.venv/bin/python -m pip install -e ../rigol-dho914s-tools
```

```bash
.venv/bin/python -m pip check
```

6. 保存先とCH別設定に対応する版か確認する。

```bash
.venv/bin/dho session --help
```

```bash
.venv/bin/dho analyze-session --help
```

`--output`、`--condition`、`--channel-items`、`--chunk-points`、解析の `--markdown` / `--json` が表示されなければ停止し、読み込まれたツール版を確認する。ツールの0.3.0改修を前提とする。

<a id="folders"></a>
## 2. 今回の保存先を作る

本リポジトリ内に全記録を置くが、**未確認の元データはGitへ追加しない**。

```text
captures/input-buffer/                 # READMEだけGit管理
└── ibuf-001/                          # 1回の作業。以下はGit管理外
    ├── input-buffer-record.md         # 実測値・条件・判断を手書き
    ├── input-buffer-record.en.md      # 必要に応じて翻訳
    ├── sessions/                      # オシロからの元ZIP
    ├── analysis/                      # 元ZIPからの解析MD・JSON
    ├── photos/                        # 配線写真の原本
    └── review/                        # ZIP展開・公開前確認用

docs/evidence/input-buffer/            # 公開確認済みの資料だけGit管理
└── ibuf-001/                          # 公開段階で作成。まだ実測結果なし
```

1. 今回のIDを決める。次回は `ibuf-002` など未使用のIDへ変える。日付や個人名をファイル名に入れる必要はない。

```bash
IBUF_RUN=ibuf-001
```

2. 作業フォルダを作る。既存の場合はエラーになるので**ここで止める**。新規測定ならIDを変え、継続なら[再開](#resume)へ進む。

```bash
mkdir "captures/input-buffer/$IBUF_RUN"
```

3. サブフォルダを作る。

```bash
mkdir -p "captures/input-buffer/$IBUF_RUN/sessions" "captures/input-buffer/$IBUF_RUN/analysis" "captures/input-buffer/$IBUF_RUN/photos" "captures/input-buffer/$IBUF_RUN/review"
```

4. 記録用ひな形をコピーする。`-n` は既存記録を上書きしない指定。

```bash
cp -n docs/templates/input-buffer-record.md "captures/input-buffer/$IBUF_RUN/input-buffer-record.md"
```

```bash
cp -n docs/templates/input-buffer-record.en.md "captures/input-buffer/$IBUF_RUN/input-buffer-record.en.md"
```

5. 誤って公開しないための除外設定を確認する。対象パスと適用規則が表示されること。表示されなければ測定データを保存する前に見直す。

```bash
git check-ignore -v "captures/input-buffer/$IBUF_RUN/sessions/check.zip" ".venv/bin/dho"
```

6. 版を確認して記録用ひな形へ転記する。コマンド出力を丸ごと公開しない。

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

ツール・FPGA側に未コミットの変更がある場合はcommit IDだけでは使用版を表せない。変更ありと記録し、測定中は変更しない。ツールの実装ファイルのSHA-256も記録する。

```bash
shasum -a 256 ../rigol-dho914s-tools/src/rigol_dho914s/*.py ../rigol-dho914s-tools/pyproject.toml
```

Gowin版、`HALF_PERIOD=5`、DRIVE、使った `.fs` のファイル名・SHA-256も記録する。次は実際に生成した**相対パス**へ置き換えてから実行する。

```bash
shasum -a 256 "<生成した試験イメージの相対パス.fs>"
```

<a id="connect"></a>
## 3. 接続と設定を確認する

**人が先に行うこと：** [無通電の確認と3V3](input-buffer-test.md#1-無通電の確認と3v3)を実施し、入力基板電源と `/OE` の値を記録する。静的試験ではNanoの信号出力をA1へつながない。PCとDHO914SのLAN設定はツールREADMEに従う。

1. 次を実行し、DHO914S本体に表示されるIPv4を入力してEnter。入力は非表示で、IPをコマンド履歴や文書へ直書きしない。

```bash
read -r -s DHO_HOST
```

```bash
export DHO_HOST
```

2. 機種照合と現在設定の読出し。

```bash
.venv/bin/dho idn
```

```bash
.venv/bin/dho status --channels 2 3
```

DHO914Sと認識されない、通信エラーがある場合は停止。接続先探索はしない。本体のCH2/CH3振幅単位が **VOLT** であることも確認する。このCLIには単位変更の指定がないので必要なら本体で変更する。

3. CH2/CH3の**プローブ実物も10X**であることを確認してから設定。1 V/divは0〜3.3 V系の試験用開始値で、未知のPS1信号へ流用しない。

```bash
.venv/bin/dho config channel --channel 2 --display ON --probe 10 --coupling DC --scale 1 --offset 0 --bandwidth OFF --invert OFF
```

```bash
.venv/bin/dho config channel --channel 3 --display ON --probe 10 --coupling DC --scale 1 --offset 0 --bandwidth OFF --invert OFF
```

使用しないCH1/CH4は表示OFFにする。プローブは試験回路以外へ接続しない。

```bash
.venv/bin/dho config channel --channel 1 --display OFF
```

```bash
.venv/bin/dho config channel --channel 4 --display OFF
```

4. 最初は静的試験用の時間軸。AUTOトリガで、信号が変化しなくても画面を更新する。

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

**確認：** 読み戻しで10X、DC、VOLT、帯域OFF、反転OFF、NORM、MAINが一致すること。電圧が画面外なら本体で表示位置・スケールを調整し記録する。設定失敗は途中まで適用される場合があるので、失敗時は再確認する。

<a id="static"></a>
## 4. 静的試験を記録する

[静的0/3V3と/OEの確認](input-buffer-test.md#2-静的03v3とoeの確認)に従う。電源OFFでRinの信号源側を変更する。Nano出力は全ケースで切り離す。各給電時はスイッチOPENで開始し、必要なケースだけ配線済みスイッチで有効にする。入力を切り替える際は再び電源OFF。

### 4-1. 入力GND、出力有効

人が配線・電源・スイッチを確認した後：

```bash
.venv/bin/dho acquire run
```

**確認：CH2/CH3ともLowで、電圧全体が画面内。** 本体値と比較できる最初の保存として1,000点のNORMALを取得する。

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

### 4-2. 入力3V3、出力有効

電源OFFで入力だけを3V3へ変更し、所定の給電・有効化を行う。

```bash
.venv/bin/dho acquire run
```

**確認：CH2/CH3ともHigh。**

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

### 4-3. 入力3V3、出力無効

配線済みスイッチをOPENにして落ち着くまで待つ。

```bash
.venv/bin/dho acquire run
```

**確認：CH2はHigh、CH3はRholdによってLowへ戻る。** Low表示だけでHi-Zの厳密な証明とはしない。

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

保存が成功したら、電圧・予想との一致を記録用ひな形へ記入する。ZIP中の `screen.png` とCSVも[公開前確認と同じ展開方法](#review)でローカル確認し、本体画面・電圧・時刻軸に整合するか確認する。NORMALは画面用の記録で、精密なエッジ時間の根拠にしない。

<a id="source"></a>
## 5. 信号源だけを確認する

**人が行うこと：** 電源OFF。静的試験の3V3/GND入力線を外し、[信号源のみの配線](ps1-input-interface.md#ブレッドボード構築イメージ)へ変更する。AD1は外し、R1〜R3とTP1を残す。Nanoの2.7 MHz専用イメージを再書込みする。CH2をTP1へ置き、CH3は使用しない。

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

**確認：** 約2.7 MHz、意図した振幅、画面内に複数周期。想定外のピーク・負側振れは、測定条件を含めて調査し、LCX541へ接続する前に止める。

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

次に小さなRAWで、点数・時間軸・電圧の取得を確認する。まず再収録する。

```bash
.venv/bin/dho acquire run
```

**確認：同じ信号が新しく収録されたこと。**

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

RAWはメモリ先頭から指定点数を取得し、画面中心だけを切り出すものではない。要求点数が適用されず失敗した場合は、本体メモリ深度・サンプルレート・時間軸を確認し、条件を直して再収録する。読み出せただけで「波形正常」と判定しない。

<a id="dynamic"></a>
## 6. 入出力を同時に記録する

### 6-1. 出力無効から開始

**人が行うこと：** 電源OFFでAD1を戻し、A1入力・Y1出力・両GNDの配線を確認する。スイッチOPENで再給電し、専用イメージを再書込みする。CH2＝TP1、CH3＝TP2。両プローブの実物10Xを再確認する。

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

**確認：CH2はクロック、CH3はLow。** 2CH表示で波形・電圧が収まること。CH追加でサンプルレートが変わる可能性も確認する。

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

### 6-2. 出力有効

配線済みスイッチを閉じて有効にする。着脱ジャンパのみなら[前提条件](#before)へ戻り、この操作を行わない。

```bash
.venv/bin/dho acquire run
```

**確認：CH3がCH2と同じ論理で変化し、両方の周波数が約2.7 MHz。**

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

同じ条件でRAWの記録も取る。NORMALとRAWは別の再収録として記録する。

```bash
.venv/bin/dho acquire run
```

**確認：波形が新しく収録され、クリッピングしていない。**

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

### 6-3. 再び出力無効

スイッチをOPENにする。比較のためCH設定・時間軸・メモリ深度は変えない。

```bash
.venv/bin/dho acquire run
```

**確認：CH2のクロックは残り、CH3だけLowへ戻る。**

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

各ZIPのCH2には周波数・High/Low・極値・rise/fallを保存する。無効時CH3は周波数を要求せず、Vavg/Vmax/Vmin/Vppにする。測定不能値が `null` ならゼロと扱わず理由を確認する。非数値・SCPI・通信エラーは保存失敗なので次へ進まない。

<a id="analysis"></a>
## 7. 保存した波形を解析する

ここからはDHO914Sへ接続せず実行できる。元ZIPを編集しない。

1. 有効時を解析する。

```bash
.venv/bin/dho analyze-session "captures/input-buffer/$IBUF_RUN/sessions/s32-enabled-raw10k.zip" \
  --from-channel 2 --to-channel 3 \
  --markdown "captures/input-buffer/$IBUF_RUN/analysis/s32-enabled-raw10k.md" \
  --json "captures/input-buffer/$IBUF_RUN/analysis/s32-enabled-raw10k.json"
```

2. 無効時を解析する。

```bash
.venv/bin/dho analyze-session "captures/input-buffer/$IBUF_RUN/sessions/s33-disabled-raw10k.zip" \
  --from-channel 2 --to-channel 3 \
  --markdown "captures/input-buffer/$IBUF_RUN/analysis/s33-disabled-raw10k.md" \
  --json "captures/input-buffer/$IBUF_RUN/analysis/s33-disabled-raw10k.json"
```

3. Markdownを開き、元画像・本体測定値と照合する。

```bash
open "captures/input-buffer/$IBUF_RUN/analysis/s32-enabled-raw10k.md"
```

```bash
open "captures/input-buffer/$IBUF_RUN/analysis/s33-disabled-raw10k.md"
```

既定アプリで開けなければエディタで開く。

- 同じ極性での動作、周波数、High/Low、Vmax/Vminをまず確認する。自動合否判定はない。
- 出力無効時の `STATIC_SIGNAL` / `PROPAGATION_UNAVAILABLE` はあり得る。ただし警告だけで正常扱いせず、実波形と電圧を確認する。ノイズで偽の周波数が出ても無効出力のクロックと断定しない。
- 解析のHigh/Lowは上下各10%のサンプルから推定した値で、本体のVTOP/VBASEとは算法が異なる。
- 解析の立上り・立下りは10–90%。LCX541の0.8〜2.0 V区間の入力傾斜判定へ、そのまま代入しない。
- 伝搬遅延はプローブ間skew・配線差を含む参考値。サンプル間隔、帯域、測定閾値とdeskewを記録し、未補正ならICの保証値と比較して合否を出さない。
- `manifest.json` の本体MAIN測定値とRAW部分CSVの解析値は、対象時間範囲が異なる場合がある。ZIPの時刻は書き出し時刻で、ハードウェアの収録時刻ではない。

<a id="larger"></a>
## 8. 任意の大きなRAW取得

初回の必須ではない。小さなRAWが正しく保存できた後、同じ配線・有効状態で転送時間や長い記録を確認したい場合だけ行う。高速な信号源への変更とは別の作業。

### 8-1. 10万点

スイッチを有効にしてから：

```bash
.venv/bin/dho config acquisition --type NORM --memory-depth 100k --area MAIN
```

```bash
.venv/bin/dho acquire run
```

**確認：** 読み戻し設定と波形、サンプルレートを確認。取得開始・完了の経過秒数を記録する。

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

### 8-2. 100万点

10万点で問題がなかった場合だけ：

```bash
.venv/bin/dho config acquisition --type NORM --memory-depth 1M --area MAIN
```

```bash
.venv/bin/dho acquire run
```

**確認：波形が新しく収録されたこと。**

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

`--timeout 120` は通信の待ち時間で、全取得が120秒以内に終わる保証ではない。進捗と実時間を見て、失敗を成功扱いしない。解析は前節と同じで入力・出力名をそれぞれのIDへ変える。サンプル間隔が粗ければ点数の多さだけで精密にならない。

<a id="finish"></a>
## 9. 終了・再開・公開

### 終了

1. スイッチOPENで出力を無効にする。
2. オシロをSTOPにする。

```bash
.venv/bin/dho acquire stop
```

3. NanoのUSB電源を外し、無通電でプローブ等を片付ける。試験イメージが次回もSRAMへ残るとは考えない。
4. 記録用ひな形の各欄を「確認できた／要再測定／未実施」で埋める。配線長、電源、プローブ、GND接続、スイッチ状態、警告、停止理由も残す。写真は `photos/` へ保存する。
5. 接続先変数を解除する。

```bash
unset DHO_HOST
```

<a id="resume"></a>
### 同じ作業の再開

新しいBashでは変数は引き継がれない。再開対象のIDを確認する。新規作業なら[保存先作成](#folders)へ戻る。

```bash
cd "$HOME/git/ps1-spdif-fpga"
```

```bash
IBUF_RUN=ibuf-001
```

```bash
test -d "captures/input-buffer/$IBUF_RUN/sessions"
```

[接続確認](#connect)と実物の確認、動的試験の再書込みをやり直す。保存済みZIPは上書きしない。再測定は各コマンドの `case` と出力ファイル名の両方に `-r02` などを付け、解析側も同じ名前へ変更する。本書では `--force` を使わない。

<a id="review"></a>
### 内容確認と公開用フォルダ

まずローカルでZIPの構成を確認する。例は有効時RAW。最初の静的記録を確認するときはIDを `s10-static-low` に読み替える。

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

`ch2.csv`、`ch3.csv`、`manifest.json` もエディタで確認する。1CHの信号源記録には `ch3.csv` はない。CSV点数・時刻軸・振幅、本体値と画像の一致を確認する。ZIPは自分でこの手順から生成したものだけを展開し、外部から入手したZIPへこの手順を流用しない。

**ここからは公開前確認後だけ。** 元ZIP・写真・解析MD/JSONのすべてについて、IP・シリアル・個人情報・ローカル絶対パス・画像メタデータ・コメントを確認する。`--note` 等は自動匿名化されない。確認できないものは公開しない。GitHubへ公開する内容と範囲をユーザーが承認した後、必要なものだけコピーする。

```bash
mkdir -p "docs/evidence/input-buffer/$IBUF_RUN"
```

例：表示内容・メタデータを確認済みのPNGだけをコピーする。原本はローカルに残す。

```bash
cp -n "captures/input-buffer/$IBUF_RUN/review/s32-enabled-raw10k/screen.png" "docs/evidence/input-buffer/$IBUF_RUN/enabled.png"
```

結果表は[記録用ひな形](templates/input-buffer-record.md)を基に公開用 `README.md` と必要に応じて `README.en.md` として作成し、[エビデンス一覧](evidence/input-buffer/README.md)へリンクする。未確認項目を落とさない。生のZIPや全CSVは自動的に追加せず、必要性・容量・公開範囲を個別に判断する。

```bash
git status --short
```

コミット・pushは本書の測定手順に含めない。公開資料は通常の差分・プライバシー確認と個別の承認手順を経る。`git add -f captures` は使わない。Git管理外の原本はGitでバックアップされないため、別途ローカルのバックアップ方法を用意する。

<a id="validation"></a>
## 検証範囲・ツール改修の要否

- ツール0.3.0のREADME、CLI、`session.py` / `files.py` / `analyze.py`を確認した。保存先は固定されておらず、`--output` と `--markdown` / `--json` で本プロジェクト内を指定できる。親フォルダは先に作る必要がある。
- **保存先変更のためのツール改修・改修依頼プロンプトは不要。** ツールリポジトリを変更せず使用する。OSや実行環境の書込み許可が必要な場合は、保存先制約とは分けて扱う。
- 2026-09-13：日英それぞれ81個のコード枠のシェル構文とCLI引数、日英のCLI一致、関連文書の111個のローカルリンク・アンカーを確認した。模擬測定器で記載の11保存コマンド（最大100万点）と2解析コマンド、ツールとは別の作業ディレクトリへの相対・絶対パス保存、ZIP構成・点数を確認した。ツール既存の自動テスト49件も成功。模擬データは一時領域だけに置き、本プロジェクトの実測エビデンスには追加していない。
- DHO914S実機通信、設定の実適用、Gowin書込み、実物の波形・電圧、公開エビデンスの取得は未実施。成功した測定として記録しない。
