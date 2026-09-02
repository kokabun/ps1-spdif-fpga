IVERILOG ?= iverilog
VVP ?= vvp
RTL = rtl/ps1_pcm_rx.v rtl/async_fifo.v rtl/spdif_tx.v rtl/ps1_spdif_core.v

.PHONY: test clean
test: build/ps1_pcm_rx_tb build/spdif_tx_tb
	$(VVP) build/ps1_pcm_rx_tb
	$(VVP) build/spdif_tx_tb

build/ps1_pcm_rx_tb: sim/ps1_pcm_rx_tb.v $(RTL)
	mkdir -p build
	$(IVERILOG) -g2005-sv -Wall -s ps1_pcm_rx_tb -o $@ $^

build/spdif_tx_tb: sim/spdif_tx_tb.v $(RTL)
	mkdir -p build
	$(IVERILOG) -g2005-sv -Wall -s spdif_tx_tb -o $@ $^

clean:
	rm -rf build
