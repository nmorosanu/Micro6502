;
;   File:           monitor.s
;   Description:    A monitor program for analyzing the memory of the system
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
.asciiz "\n\rMONITOR PROGRAM\n\rBoth you and the computer draw 2 cards at first.\n\rType 'h' to print the help menu.\n\r"
msg_help:
.asciiz "MONITOR HELP\n\rUSAGE EXAMPLES:\n\r*    r 4000:4FFF     ~   Retrieves the memory contained at [4000, 4FFF]\n\r*    r 4007:         ~   Retrieves the memory contained at [4007, 400F]\n\r*    r FFFA          ~   Retrieves the value at address FFFA\n\r\n\r*    w 3000:30AA 80  ~   Writes 80 in the addresses contained within [3000, 30AA]\n\r*    w 220A: AF      ~   Writes AF in the addresses contained within [220A, 220F]\n\r*    w 5555 7F       ~   Writes 7F at address 5555\n\r\n\rANY ATTEMPT TO TAMPER WITH SPECIAL MEMORY ZONES WILL BE REJECTED!\n\r"
msg_quit:
.asciiz "Quitting monitor.\n\r"

;QUIT    =   $00

.export _monitor_init
_monitor_init:
@loop:                                      ;
    jsr     monitor_loop                    ;
    ;lda     QUIT                            ;
    ;beq     @loop
    bra     @loop

monitor_loop:
    jsr     monitor_help
    jsr     monitor_quit
    rts

monitor_quit:
    lda     #<msg_quit
    sta     ZP_STRING_BUFFER
    lda     #>msg_quit
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

    ;inc     QUIT
    jmp     ($FFF8)                         ;   Salt la "HOME".
    
    rts

monitor_buffer_parse:
    rts

monitor_help:
    pha

    lda     #<msg_help
    sta     ZP_STRING_BUFFER
    lda     #>msg_help
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

    pla
    rts
