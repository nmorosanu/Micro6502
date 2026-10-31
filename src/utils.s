;
;   File:           utils.s
;   Description:    Some subroutines which can be used in one or more submodules / programs
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       31.10.2026
;   Version:        0.0.1
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"

.code
.export num2str
num2str:
    pha
    phx
    
    ldx     #0
@sute:
    cmp     #100
    bcc     @sute_end
    sec
    sbc     #100
    inx
    bra     @sute

@sute_end:
    txa
    clc
    adc     #'0'
    sta     NUM2STR                 ;   NUM2STR[0] = A / 100 % 10 + '0'

    ldx     #0
@zeci:
    cmp     #10
    bcc     @zeci_end
    sec
    sbc     #10
    inx
    bra     @zeci
@zeci_end:
    txa
    clc
    adc     #'0'
    sta     NUM2STR + 1             ;   NUM2STR[1] = A / 10 % 10 + '0'

    clc
    adc     #'0'
    sta     NUM2STR + 2             ;   NUM2STR[2] = A % 10 + '0'
    stz     NUM2STR + 3             ;   NUM2STR[3] = '\0'

    plx
    pla
    rts

.export sys_prng
sys_prng:
    lda     PRNG_SEED
    tax
    
    asl
    eor     PRNG_SEED
    asl
    eor     PRNG_SEED
    asl
    eor     PRNG_SEED
    asl
    eor     PRNG_SEED
    asl
    eor     PRNG_SEED
    asl
    eor     PRNG_SEED
    asl
    eor     PRNG_SEED
    asl
    eor     PRNG_SEED
    sta     PRNG_SEED

@mod:
    sec
@modloop:
    sbc     PRNG_VAL_MAX
    bcs     @modloop
    
    adc     PRNG_VAL_MAX
    rts

.export sys_crc16_modbus
sys_crc16_modbus:
    lda     #$FF                    ;
    sta     CRC                     ;
    sta     CRC + 1                 ;   CRC = xFFFF
    
    ldy     #$00
@loop_bytes:
    lda     (ZP_STRING_BUFFER), y   ;
    beq     @end                    ;   XOR byte and store
    eor     CRC                     ;   the result
    sta     CRC                     ;

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

.export sys_crc16modbus_cmp
sys_crc16modbus_cmp:
@lbyte:
    lda     CRC
    cmp     CRC_COMPARE
    bne     @end
@hbyte:
    lda     CRC         + 1
    cmp     CRC_COMPARE + 1
@end:
    rts
