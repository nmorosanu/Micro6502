.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
msg:
    .asciiz "PROGRAM!!!"
.code

.export _program_init
_program_init:
    lda     #<msg
    sta     ZP_STRING_BUFFER
    lda     #>msg
    sta     ZP_STRING_BUFFER + 1
    jsr     _uart_write_string
@loop:
    bra     @loop
