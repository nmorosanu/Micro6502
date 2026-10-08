.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
.code
.export crc16clc
crc16clc:
    lda     #$FF                    ;
    sta     CRC                     ;
    sta     CRC + 1                 ;   CRC = xFFFF
    
    ldy     #$00
@loop_bytes:
    lda     (ZP_STRING_BUFFER), y
    beq     @end
    eor     CRC
    sta     CRC

    ldx     #$08
@loop_bits:
    lsr     CRC + 1                 ;
    ror     CRC                     ;   Check if LSB is set
    bcc     @skip_xor
@xor:
    lda     CRC                     ;
    eor     #$01                    ;   XOR low byte
    sta     CRC                     ;
    lda     CRC + 1                 ;
    eor     #$A0                    ;   XOR high byte
    sta     CRC + 1                 ;
@skip_xor:
    dex
    bne     @loop_bits
    
    iny
    bne     @loop_bytes
    inc     ZP_STRING_BUFFER + 1
    bra     @loop_bytes
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
