IVERILOG ?= iverilog
VVP ?= vvp
RTL = rtl/ps1_pcm_rx.v rtl/async_fifo.v rtl/spdif_tx.v rtl/ps1_spdif_core.v rtl/reset_release.v

.PHONY: test test-input-buffer clean
test: build/ps1_pcm_rx_tb build/spdif_tx_tb test-input-buffer
	$(VVP) build/ps1_pcm_rx_tb
	$(VVP) build/spdif_tx_tb
	python3 sim/run_regression.py

test-input-buffer: build/test_clock_divider_tb
	$(VVP) build/test_clock_divider_tb

build/test_clock_divider_tb: sim/test_clock_divider_tb.v rtl/test_clock_divider.v platform/tang_nano_9k/input_buffer_test/top.v
	mkdir -p build
	$(IVERILOG) -g2005-sv -Wall -s test_clock_divider_tb -o $@ $^

build/ps1_pcm_rx_tb: sim/ps1_pcm_rx_tb.v $(RTL)
	mkdir -p build
	$(IVERILOG) -g2005-sv -Wall -s ps1_pcm_rx_tb -o $@ $^

build/spdif_tx_tb: sim/spdif_tx_tb.v $(RTL)
	mkdir -p build
	$(IVERILOG) -g2005-sv -Wall -s spdif_tx_tb -o $@ $^

clean:
	rm -rf build
