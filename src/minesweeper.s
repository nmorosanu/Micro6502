;
;   File:           minesweeper.s
;   Description:    Minesweeper game over UART.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       29.10.2026
;   Version:        0.0.1
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
minesweeper_msg_init:   .asciiz "  INIT MINESWEEPER"
minesweeper_msg_lives:  .asciiz "  Lives: "
minesweeper_msg_win:    .asciiz "You win!"
minesweeper_msg_lose:   .asciiz "You lost!"

.code
.export _minesweeper_init
_minesweeper_init:
    lda     #<minesweeper_msg_init
    sta     ZP_STRING_BUFFER
    lda     #>minesweeper_msg_init
    sta     ZP_STRING_BUFFER + 1
    jsr     func_uart_string_write
@loop:
    bra     @loop
