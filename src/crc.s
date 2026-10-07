.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
.code
.export crc16clc
crc16clc:
    lda     #$FF                    ;
    sta     CRC                     ;
    sta     CRC + 1                 ;   CRC = xFFFF
    
    lda     CRC_LENGTH
    ora     CRC_LENGTH + 1
    beq     @end
    
    ldy     #$00
@loop_bytes:
    lda     (ZP_STRING_BUFFER), y
    eor     CRC
    sta     CRC

    ldx     #$08
@loop_bits:
    lsr     CRC + 1                 ;
    ror     CRC                     ;   Check if LSB is set
    bcc     @skip_xor

    lda     CRC + 1
    eor     #$A0
    sta     CRC + 1
    lda     CRC
    eor     #$01
    sta     CRC
@skip_xor:
    dex
    bne     @loop_bits

    inc     ZP_STRING_BUFFER
    bne     @decrement_page
    inc     ZP_STRING_BUFFER + 1
@decrement_page:
    lda     CRC_LENGTH
    bne     @decrement_length
    dec     CRC_LENGTH + 1
@decrement_length:
    lda     CRC_LENGTH
    dec
    ora     CRC_LENGTH + 1
    bne     @loop_bytes
@end:
    rts

.export crc16cmp
crc16cmp:
@lbyte:
    lda     CRC
    cmp     CRC_COMPARE
    bne     @end
@hbyte:
    lda     CRC         + 1
    cmp     CRC_COMPARE + 1
@end:
    rts
