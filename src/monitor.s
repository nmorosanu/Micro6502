;
;   File:           monitor.s
;   Description:    A monitor program for analyzing the memory of the system
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       29.10.2026
;   Version:        0.0.1
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
_monitor_msg_help:          .asciiz "MONITOR HELP\n\rUSAGE EXAMPLES:\n\r*    r 4000:4FFF     ~   Retrieves the memory contained at [4000, 4FFF]\n\r*    r 4007:         ~   Retrieves the memory contained at [4007, 400F]\n\r*    r FFFA          ~   Retrieves the value at address FFFA\n\r\n\r*    w 3000:30AA 80  ~   Writes 80 in the addresses contained within [3000, 30AA]\n\r*    w 220A: AF      ~   Writes AF in the addresses contained within [220A, 220F]\n\r*    w 5555 7F       ~   Writes 7F at address 5555\n\r\n\rANY ATTEMPT TO TAMPER WITH SPECIAL MEMORY ZONES WILL BE REJECTED!\n\r"

.export _monitor_init
_monitor_init:
@loop:
    bra     @loop
