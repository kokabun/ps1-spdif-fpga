create_clock -name clk_27m -period 37.037 [get_ports {clk_27m}]
# No external synchronous receiver is connected: test_out is an oscilloscope source.
# No external setup/hold or analog waveform guarantee is implied by this constraint.
# This project has no PLL. Clock-to-pad delay/skew must be checked in P&R and on hardware.
