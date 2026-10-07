.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
_msg_monitor_init:   .asciiz "  MEMORY MONITOR"

MEM_SRC = $F0
MEM_DST = $F2

.code
.export monitor_init
monitor_init:
    lda     #<_msg_monitor_init
    ldy     #>_msg_monitor_init
    jsr     _uart_write_string
@ib_parse:
    

