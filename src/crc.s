.include "inc/memory.inc"
.include "inc/peripherals.inc"

LENGTH      = $00F0
CRC         = $00F1
CRCCompare  = $00F4

.rodata
crc16modbus_compute:
    sty     LENGTH
    
    lda     #$FF         ;
    sta     CRC          ;   start with 0xFFFF
    sta     CRC + 1      ;
    
    lda     LENGTH
    ora     LENGTH + 1
    beq     @end

    ldy     #$00
@loop_word:
    lda     (zp_string_buffer), Y
    eor     CRC
    sta     CRC
    ldx     #$08
@loop_bit:
    lsr     CRC + 1
    ror     CRC
    bcc     @shift
    
    lda     CRC + 1
    eor     #$A0
    sta     CRC + 1
    lda     CRC
    eor     #$01
    sta     CRC
@shift:
    dex
    bne     @loop_bit
    inc     zp_string_buffer
    bne     @increment_ptr
    inc     zp_string_buffer + 1
@increment_ptr:
    lda     LENGTH
    bne     @continue
    dec     LENGTH + 1
@continue:
    dec     LENGTH
    lda     LENGTH
    bne     @loop_word
@end:
    rts

crc16modbus_verify:
    stz     CRCCompare
    stz     CRCCompare + 1
@lbyte:
    cmp     CRC
    beq     @hbyte
    bra     @wrong
@hbyte:
    cpx     CRC + 1
    beq     @end
@wrong:
    lda     #$DE
    sta     CRCCompare
    lda     #$AD
    sta     CRCCompare + 1
@end:
    rts

.export crc16modbus_compute
.export crc16modbus_verify
