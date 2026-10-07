.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
.code
.export crc16clc
crc16clc:
    sty     crc_length
    
    lda     #$FF                        ;
    sta     crc                         ;   start with 0xFFFF
    sta     crc + 1                     ;
    
    lda     crc_length                  ;   check length (y)
    ora     crc_length + 1              ;   if (length == 0)
    beq     @end                        ;       return;

    ldy     #$00
@loop_word:
    lda     (zp_string_buffer), Y
    eor     crc
    sta     crc
    ldx     #$08
@loop_bit:
    lsr     crc + 1
    ror     crc
    bcc     @shift
    
    lda     crc + 1
    eor     #$A0
    sta     crc + 1
    lda     crc
    eor     #$01
    sta     crc
@shift:
    dex
    bne     @loop_bit
    inc     zp_string_buffer
    bne     @increment_ptr
    inc     zp_string_buffer + 1
@increment_ptr:
    lda     crc_length
    bne     @continue
    dec     crc_length + 1
@continue:
    dec     crc_length
    lda     crc_length
    bne     @loop_word
@end:
    rts

.export crc16cmp
crc16cmp:
@lbyte:
    lda     crc
    cmp     crc_compare
    bne     @end
@hbyte:
    lda     crc         + 1
    cmp     crc_compare + 1
@end:
    rts
