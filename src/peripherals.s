.include    "./inc/memory.inc"

.code
.export _peripherals_config
_peripherals_config:
    ;       =================
    ;       VIA CONFIGURATION
    ;       =================
    lda     #$FF
    sta     VIA_DDRA            ;
    stz     VIA_PORTA           ;
    sta     VIA_DDRB            ;   PORTA = PORTB = x00
    stz     VIA_PORTB           ;

    ;       ==================
    ;       ACIA CONFIGURATION
    ;       ==================
    stz     ACIA_STATUS         ;   soft reset
    lda     #$1F
    sta     ACIA_CONTROL
    lda     #$09
    sta     ACIA_COMMAND

    ldx     #$FF                ;
@b0:                                    ;
    lda     #$FF                ;
@b1:        dec                         ;   delay scurt pentru LCD
    bne     @b1                 ;
    dex                         ;
    bne     @b0                 ;

    lda     #$02                ;
    jsr     _lcd_command        ;

    lda     #$28                ;
    jsr     _lcd_command        ;

    lda     #$06                ;
    jsr     _lcd_command        ;

    lda     #$0C                ;
    jsr     _lcd_command        ;

    lda     #$01                ;
    jsr     _lcd_command        ;
    lda     #$80                ;
    jsr     _lcd_command        ;   CLEAR

    rts

.export     _lcd_delay
_lcd_delay:   pha
    lda     #$30
@loop:
    dec
    bne     @loop

    pla
    rts

.export _lcd_clear
_lcd_clear:
    pha
    lda     #$01
    jsr     _lcd_command
    lda     #$80
    jsr     _lcd_command
    pla
    rts

.export _lcd_command
_lcd_command:
    sta     $00
    and     #$F0
    ora     #$08
    sta     VIA_PORTB

    jsr     _lcd_delay

    and     #$F0
    sta     VIA_PORTB

    jsr     _lcd_delay

    lda     $00
    rol
    rol
    rol
    rol
    and     #$F0
    ora     #$08
    sta     VIA_PORTB

    jsr     _lcd_delay

    and     #$F0
    sta     VIA_PORTB

    jsr     _lcd_delay

    pla
    rts

.export _lcd_write_char
_lcd_write_char:
    sta     $00
    and     #$F0
    ora     #$0C
    sta     VIA_PORTB

    jsr     _lcd_delay

    and     #$F4
    sta     VIA_PORTB

    jsr     _lcd_delay

    lda     $00
    rol
    rol
    rol
    rol
    and     #$F0
    ora     #$0C
    sta     VIA_PORTB

    jsr     _lcd_delay

    and     #$F4
    sta     VIA_PORTB

    jsr     _lcd_delay
    lda     $00

    rts

.export _lcd_write_string
_lcd_write_string:  
    sta     zp_string_buffer
    sty     zp_string_buffer + 1
    ldy     #$00
@loop:      lda     (zp_string_buffer), y
    beq     @end

    jsr     _lcd_write_char
    iny

    bra     @loop

@end:       
    lda     zp_string_buffer
    ldy     zp_string_buffer + 1
    rts

.export _uart_read_byte
_uart_read_byte:
    pha
@poll:
    lda     ACIA_STATUS
    bit     #$08
    beq     @poll

    lda     ACIA_DATA

    rts

.export _uart_write_byte
_uart_write_byte:   
    sta     ACIA_DATA
    pha
    lda     #$FF                    ;
@b0:                                ;   artificial delay to counter the WDC65C51 hardware bug
    dec                             ;
    bne     @b0
    pla
    rts

.export _uart_write_string
_uart_write_string:
    ldy     #$00
@loop:      
    lda     (zp_string_buffer), y
    beq     @end

    sta     ACIA_DATA
    lda     #$FF                    ;
@b0:                                ;   artificial delay to counter the WDC65C51 hardware bug
    dec                             ;
    bne     @b0
    iny

    bra     @loop

@end:       
    rts

.export     acia_irq
acia_irq:   
    pha
    phx

    jsr     _uart_read_byte

    ldx     ib_base
    sta     ib_base, x

    cmp     #$0D                ;   CR?
    beq     @CR

    jsr     _uart_write_byte
    inx
    bra     @end

@CR:
    jsr     _uart_write_byte
    lda     #$0A
    jsr     _uart_write_byte
    ldx     #$00
@end:
    stx     ib_idx
    plx
    pla

    rts

.export     via_irq
via_irq:    
    pha
    pla
    rts
