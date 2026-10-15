.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
_msg_lives:  .asciiz "  Lives: "
_msg_win:    .asciiz "You win!"
_msg_lose:   .asciiz "You lost!"
msg:
    .asciiz "PROGRAM!!!"

.code
.export _minesweeper_init
_minesweeper_init:
    lda     #<msg
    sta     ZP_STRING_BUFFER
    lda     #>msg
    sta     ZP_STRING_BUFFER + 1
    jsr     _uart_write_string
@loop:
    bra     @loop
