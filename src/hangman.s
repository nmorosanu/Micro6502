;
;   File:           hangman.s
;   Description:    Hangman game over UART.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       29.10.2026
;   Version:        0.0.1
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"
.include "inc/utils.inc"

.rodata


.data
QUIT    =   $00

.code
.global _hangman_init
_hangman_init:
@loop:
    bra     @loop
