;
;   File:           monitor.s
;   Description:    A monitor program for analyzing the system's memory.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       01.11.2026
;   Version:        0.0.1
;   

;
;   In curs de dezvoltare.
;

.include "inc/memory.inc"
.include "inc/utils.inc"
.include "inc/peripherals.inc"

.feature string_escapes

.rodata
msg_init:
.asciiz "\n\rMONITOR PROGRAM\n\rA simple utility for monitoring the system's memory.\n\rTrying to write into special locations will result in an error.\n\r"
msg_help:
.asciiz "MONITOR HELP\n\rUSAGE EXAMPLES:\n\r*    r 4000:4FFF     ~   Retrieves the memory contained at [4000, 4FFF]\n\r*    r 4007:         ~   Retrieves the memory contained at [4007, 400F]\n\r*    r FFFA          ~   Retrieves the value at address FFFA\n\r\n\r*    w 3000:30AA 80  ~   Writes 80 in the addresses contained within [3000, 30AA]\n\r*    w 220A: AF      ~   Writes AF in the addresses contained within [220A, 220F]\n\r*    w 5555 7F       ~   Writes 7F at address 5555\n\r\n\rANY ATTEMPT TO TAMPER WITH SPECIAL MEMORY ZONES WILL BE REJECTED!\n\r"
msg_quit:
.asciiz "Quitting monitor.\n\r"
msg_error:
.asciiz "Invalid command.\n\r"

.export _monitor_init
_monitor_init:
@loop:
    jsr     _monitor_loop
    bra     @loop

_monitor_loop:
    jsr     _monitor_buffer_parse
    rts

_monitor_quit:
    lda     #<msg_quit
    sta     ZP_STRING_BUFFER
    lda     #>msg_quit
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

    jmp     ($FFF8)                         ;   Salt la "HOME".
    
    rts

_monitor_buffer_parse:
    lda     IB_BASE
    cmp     #'q'
    beq     @quit
    cmp     #'h'
    beq     @help
    
    lda     #<msg_error
    sta     ZP_STRING_BUFFER
    lda     #>msg_error
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
@quit:
    jsr     _monitor_quit
    bra     @end
@help:
    jsr     _monitor_help
@end:

    dec     IB_READY
    rts

_monitor_help:
    pha

    lda     #<msg_help
    sta     ZP_STRING_BUFFER
    lda     #>msg_help
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

    pla
    rts
