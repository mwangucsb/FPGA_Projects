## Clock
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]


# Reset button
#set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports {reset}]; #reset, cpu_reset
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports {reset}]; #btnc
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports {start}]; #btnl
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports {select}]; #btnr
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {rd}]; #btnu
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports {wr}]; #btnd
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { select_buffer }]; #CPU_RESETN


#LED
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { led }]; #IO_L11P_T1_SRCC_14 Sch=led16_r


#Switch
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L24N_T3_RS0_15 Sch=sw[0]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=sw[1]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L6N_T0_D08_VREF_14 Sch=sw[2]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L13N_T2_MRCC_14 Sch=sw[3]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { sw[4] }]; #IO_L12N_T1_MRCC_14 Sch=sw[4]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { sw[5] }]; #IO_L7N_T1_D10_14 Sch=sw[5]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { sw[6] }]; #IO_L17N_T2_A13_D29_14 Sch=sw[6]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { sw[7] }]; #IO_L5N_T0_D07_14 Sch=sw[7]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { sw[8] }]; #IO_L24N_T3_34 Sch=sw[8]
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports { sw[9] }]; #IO_25_34 Sch=sw[9]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { sw[10] }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=sw[10]
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { sw[11] }]; #IO_L23P_T3_A03_D19_14 Sch=sw[11]
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { sw[12] }]; #IO_L24P_T3_35 Sch=sw[12]
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { sw[13] }]; #IO_L20P_T3_A08_D24_14 Sch=sw[13]
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { sw[14] }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=sw[14]
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { sw[15] }]; #IO_L21P_T3_DQS_14 Sch=sw[15]
## Seven-segment display segments, both LED displays have the same behavior
## sseg[0] = CA
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {sseg[0]}]

## sseg[1] = CB
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports {sseg[1]}]

## sseg[2] = CC
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports {sseg[2]}]

## sseg[3] = CD
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports {sseg[3]}]

## sseg[4] = CE
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports {sseg[4]}]

## sseg[5] = CF
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports {sseg[5]}]

## sseg[6] = CG
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {sseg[6]}]

## sseg[7] = DP
set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports {sseg[7]}]


## Seven-segment display anodes
## an[0] = AN0
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {an[0]}]

## an[1] = AN1
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {an[1]}]

## an[2] = AN2
set_property -dict { PACKAGE_PIN T9 IOSTANDARD LVCMOS33 } [get_ports {an[2]}]

## an[3] = AN3
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports {an[3]}]

#an[4]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { an[4] }]; #IO_L8N_T1_D12_14 Sch=an[4]

#an[5]
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { an[5] }]; #IO_L14P_T2_SRCC_14 Sch=an[5]

#an[6]
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { an[6] }]; #IO_L23P_T3_35 Sch=an[6]

#an[7]
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { an[7] }]; #IO_L23N_T3_A02_D18_14 Sch=an[7]