# Signal mapping for MEGA65 platform revision 3
#
# Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).


#############################################################################################################
# Pin locations and I/O standards
#############################################################################################################

## External clock signal (connected to 100 MHz oscillator)
set_property -dict {PACKAGE_PIN V13  IOSTANDARD LVCMOS33}                                    [get_ports {sys_clk_i}]

## Reset signal (Active low. From MAX10)
set_property -dict {PACKAGE_PIN M13  IOSTANDARD LVCMOS33}                                    [get_ports {sys_rstn_i}]

## HyperRAM (connected to IS66WVH8M8BLL-100B1LI, 64 Mbit, 100 MHz, 3.0 V, single-ended clock).
## SLEW and DRIVE set to maximum performance to reduce rise and fall times, and therefore
## give better timing margins.
set_property -dict {PACKAGE_PIN B22  IOSTANDARD LVCMOS33  PULLTYPE {}                          } [get_ports {hr_resetn}]
set_property -dict {PACKAGE_PIN C22  IOSTANDARD LVCMOS33  PULLTYPE {}                          } [get_ports {hr_csn}]
set_property -dict {PACKAGE_PIN D22  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_ck}]
set_property -dict {PACKAGE_PIN B21  IOSTANDARD LVCMOS33  PULLTYPE PULLDOWN SLEW FAST  DRIVE 16} [get_ports {hr_rwds}]
set_property -dict {PACKAGE_PIN A21  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[0]}]
set_property -dict {PACKAGE_PIN D21  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[1]}]
set_property -dict {PACKAGE_PIN C20  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[2]}]
set_property -dict {PACKAGE_PIN A20  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[3]}]
set_property -dict {PACKAGE_PIN B20  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[4]}]
set_property -dict {PACKAGE_PIN A19  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[5]}]
set_property -dict {PACKAGE_PIN E21  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[6]}]
set_property -dict {PACKAGE_PIN E22  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq[7]}]

## Keyboard interface (connected to MAX10)
set_property -dict {PACKAGE_PIN A14  IOSTANDARD LVCMOS33}                                    [get_ports {kb_io0}]
set_property -dict {PACKAGE_PIN A13  IOSTANDARD LVCMOS33}                                    [get_ports {kb_io1}]
set_property -dict {PACKAGE_PIN C13  IOSTANDARD LVCMOS33}                                    [get_ports {kb_io2}]

# USB-RS232 Interface
set_property -dict {PACKAGE_PIN L14  IOSTANDARD LVCMOS33} [get_ports {uart_rx_i}];
set_property -dict {PACKAGE_PIN L13  IOSTANDARD LVCMOS33} [get_ports {uart_tx_o}];

# HDMI output
set_property -dict {PACKAGE_PIN Y1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_n}]
set_property -dict {PACKAGE_PIN W1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_p}]
set_property -dict {PACKAGE_PIN AB1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n[0]}]
set_property -dict {PACKAGE_PIN AA1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p[0]}]
set_property -dict {PACKAGE_PIN AB2  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n[1]}]
set_property -dict {PACKAGE_PIN AB3  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p[1]}]
set_property -dict {PACKAGE_PIN AB5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n[2]}]
set_property -dict {PACKAGE_PIN AA5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p[2]}]


############################################################################################################
# Clocks
############################################################################################################

## Primary clock input
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_i]


########### HypeRAM timing #################
# Rename autogenerated clocks
create_generated_clock -name delay_refclk [get_pins i_clk/i_clk_hyperram/CLKOUT1]
create_generated_clock -name hr_clk_del   [get_pins i_clk/i_clk_hyperram/CLKOUT2]
create_generated_clock -name hr_clk       [get_pins i_clk/i_clk_hyperram/CLKOUT3]

# HyperRAM output clock relative to delayed clock
create_generated_clock -name hr_ck         [get_ports hr_ck] \
   -source [get_pins i_clk/i_clk_hyperram/CLKOUT2] -multiply_by 1

# HyperRAM RWDS as a clock for the read path (hr_dq -> IDDR -> CDC)
create_clock -period 10.000 -name hr_rwds -waveform {2.5 7.5} [get_ports hr_rwds]

# Asynchronous clocks
set_false_path -from [get_ports hr_rwds] -to [get_clocks hr_ck]

# Clock Domain Crossing
set_max_delay 2 -datapath_only -from [get_cells i_core/i_hyperram/hyperram_ctrl_inst/hb_read_o_reg]
set_max_delay 2 -datapath_only -from [get_cells i_core/i_hyperram/hyperram_rx_inst/iddr_dq_gen[*].iddr_dq_inst]

# Prevent insertion of extra BUFG
set_property CLOCK_BUFFER_TYPE NONE [get_nets -of [get_pins i_core/i_hyperram/hyperram_rx_inst/delay_rwds_inst/DATAOUT]]

# Receive FIFO: There is a CDC in the LUTRAM.
# There is approx 1.1 ns Clock->Data delay for the LUTRAM itself, plus 0.5 ns routing delay to the capture flip-flop.
set_max_delay 2 -datapath_only -from [get_clocks hr_rwds] -to [get_clocks hr_clk]

################################################################################
# HyperRAM timing (correct for IS66WVH8M8DBLL-100B1LI)

set tCKHP    5.0 ; # Clock Half Period
set HR_tIS   1.0 ; # input setup time
set HR_tIH   1.0 ; # input hold time
set tDSSmax  0.8 ; # RWDS to data valid, max
set tDSHmin -0.8 ; # RWDS to data invalid, min

################################################################################
# FPGA to HyperRAM (address and write data)

set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_tx_inst/hr_rwds_oe_n_reg ]
set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_tx_inst/hr_dq_oe_n_reg[*] ]
set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_ctrl_inst/hb_csn_o_reg ]
set_property IOB TRUE [get_cells i_core/i_hyperram/hyperram_ctrl_inst/hb_rstn_o_reg ]

# setup
set_output_delay -max  $HR_tIS -clock hr_ck [get_ports {hr_resetn hr_csn hr_rwds hr_dq[*]}]
set_output_delay -max  $HR_tIS -clock hr_ck [get_ports {hr_resetn hr_csn hr_rwds hr_dq[*]}] -clock_fall -add_delay

# hold
set_output_delay -min -$HR_tIH -clock hr_ck [get_ports {hr_resetn hr_csn hr_rwds hr_dq[*]}]
set_output_delay -min -$HR_tIH -clock hr_ck [get_ports {hr_resetn hr_csn hr_rwds hr_dq[*]}] -clock_fall -add_delay

################################################################################
# HyperRAM to FPGA (read data, clocked in by RWDS)
# edge aligned, so pretend that data is launched by previous edge

# setup
set_input_delay -max [expr $tCKHP + $tDSSmax] -clock hr_rwds [get_ports hr_dq[*]]
set_input_delay -max [expr $tCKHP + $tDSSmax] -clock hr_rwds [get_ports hr_dq[*]] -clock_fall -add_delay

# hold
set_input_delay -min [expr $tCKHP + $tDSHmin] -clock hr_rwds [get_ports hr_dq[*]]
set_input_delay -min [expr $tCKHP + $tDSHmin] -clock hr_rwds [get_ports hr_dq[*]] -clock_fall -add_delay


########### MEGA65 timing ################
# Rename autogenerated clocks
create_generated_clock -name kbd_clk    [get_pins i_mega65/i_clk_mega65/i_clk_mega65/CLKOUT0]
create_generated_clock -name pixel_clk  [get_pins i_mega65/i_clk_mega65/i_clk_mega65/CLKOUT1]
create_generated_clock -name pixel_clk5 [get_pins i_mega65/i_clk_mega65/i_clk_mega65/CLKOUT2]

# MEGA65 I/O timing is ignored (considered asynchronous)
set_false_path   -to [get_ports hdmi_data_p[*]]
set_false_path   -to [get_ports hdmi_clk_p]
set_false_path   -to [get_ports kb_io0]
set_false_path   -to [get_ports kb_io1]
set_false_path -from [get_ports kb_io2]


#############################################################################################################
# Configuration and Bitstream properties
#############################################################################################################

set_property CONFIG_VOLTAGE                  3.3   [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]

