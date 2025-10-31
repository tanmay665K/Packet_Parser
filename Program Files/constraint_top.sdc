# Clock Definition
create_clock -name clk -period 2 -waveform {0 1} [get_ports "clk"]

# Clock Transitions
set_clock_transition -rise 0.1 [get_clocks "clk"]
set_clock_transition -fall 0.1 [get_clocks "clk"]

# Clock Uncertainty
set_clock_uncertainty 0.01 [get_clocks "clk"]

# Input Delays (relative to clk)
set_input_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "rst_n"]
set_input_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "packet_in"]
set_input_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "packet_valid"]

# Output Delays (relative to clk)
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "packet_accepted"]
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "packet_rejected"]
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "audio_data"]
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "device_id"]
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "sequence_num"]
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "bus_key"]
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "bus_grant"]
set_output_delay -max 1.0 -clock [get_clocks "clk"] [get_ports "bus_busy"]

# (Optional) False paths or multi-cycle paths can be added depending on functional behavior
# Example:
# set_false_path -from [get_ports rst_n]
