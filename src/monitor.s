.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
_msg_monitor_init:   .asciiz "  MEMORY MONITOR"

MEM_SRC = $2000
MEM_DST = $2002

.code
.export monitor_init
monitor_init:
    lda     #<_msg_monitor_init
    ldy     #>_msg_monitor_init
    jsr     _uart_write_string
@ib_parse:
    

