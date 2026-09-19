//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.12.03 (64-bit) 
//Created Time: 2026-09-19 15:56:29
create_clock -name SYS_CLK -period 20 -waveform {0 10} [get_ports {SYS_CLK}]
create_clock -name SD_CLK -period 571.429 -waveform {0 285.714} [get_ports {SD_CLK}]
