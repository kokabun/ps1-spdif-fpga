// 未測定テンプレート。現状では実機用タイミング制約は有効ではない。
// 手順・測定表・CDC経路一覧: ../../docs/timing-validation.md
// 単位はns。TBDを実測と余裕から決定し、対象行を有効化する。
// create_clock -name ps1_wcko -period <WCKO_PERIOD_NS> [get_ports {ps1_wcko}]
// create_clock -name ps1_bcko -period <BCKO_PERIOD_NS> [get_ports {ps1_bcko}]
// デューティ比が非対称なら-waveformも指定する。

// 下記は立上り基準の構文例。信号の送出基準が立下りなら-clock_fallを追加。
// SAMPLE_ON_NEGEDGEと送出基準エッジは別の概念。必ず実測から選ぶ。
// set_input_delay -clock ps1_bcko -min <DATO_MIN_NS> [get_ports {ps1_dato}]
// set_input_delay -clock ps1_bcko -max <DATO_MAX_NS> [get_ports {ps1_dato}]
// set_input_delay -clock ps1_bcko -min <LRCO_MIN_NS> [get_ports {ps1_lrco}]
// set_input_delay -clock ps1_bcko -max <LRCO_MAX_NS> [get_ports {ps1_lrco}]

// CDC: 合成後の実在するノード名で、Grayポインタから第1同期段までを両方向に指定。
// 下記の対象名は説明用でありGowinが生成する階層名を保証しない。
// set_max_delay -from [get_regs {<WR_GRAY_REGS>}] -to [get_regs {<WR_GRAY_R1_REGS>}] <WR_CDC_MAX_NS>
// set_max_delay -from [get_regs {<RD_GRAY_REGS>}] -to [get_regs {<RD_GRAY_W1_REGS>}] <RD_CDC_MAX_NS>
// Gray各ビットの実配線遅延・スキューが送信元の最短周期以内となるよう確認する。
// この例だけでCDC制約完了とはしない。同期段間、FIFOデータ経路、resetも別途確認。
// 一括set_false_path/set_clock_groupsで上記経路を解析対象外にしない。
// 採用EDAで例外の適用対象と優先順位を確認し、report_timing等の結果を残す。
