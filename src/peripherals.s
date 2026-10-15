.include    "./inc/memory.inc"

.code
.export _peripherals_config
_peripherals_config:
    ;       =================
    ;       VIA CONFIGURATION
    ;       =================
    lda     #$FF
    sta     VIA_DDRA            ;
    sta     VIA_DDRB            ;   PORTA = 0x00    (OUTPUT)
    stz     VIA_PORTA           ;   PORTB = 0x00    (OUTPUT)
    stz     VIA_PORTB           ;

    ;       ==================
    ;       ACIA CONFIGURATION
    ;       ==================
    stz     ACIA_STATUS         ;   soft reset

    lda     #$10                ;
    sta     ACIA_CONTROL        ;   1 stop bit, 8-bit word, 19200bps

    lda     #$09                ;
    sta     ACIA_COMMAND        ;   

    ;       ==================
    ;       LCD INITIALIZATION
    ;       ==================
    ;jsr     _lcd_delay
    ;lda     #$33                ;
    ;jsr     _lcd_command        ;
    ;lda     #$32                ;
    ;jsr     _lcd_command        ;
    ;lda     #$28                ;
    ;jsr     _lcd_command        ;
    ;lda     #$0C                ;
    ;jsr     _lcd_command        ;
    ;lda     #$06                ;
    ;jsr     _lcd_command        ;
    ;lda     #$01                ;
    ;jsr     _lcd_command        ;
    ;lda     #$80                ;
    ;jsr     _lcd_command        ;

    rts

.export     _lcd_delay
_lcd_delay:   
    phx
    ldx     #$FF
@dx:
    dex
    bne     @dx
    plx
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
    ldy     #$00
@loop:      lda     (ZP_STRING_BUFFER), y
    beq     @end

    jsr     _lcd_write_char
    iny

    bra     @loop

@end:       
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
    lda     #$FF
@b0:
    dec
    bne     @b0
    pla
    rts

.export _uart_write_string
_uart_write_string:
    ldy     #$00
@loop:      
    lda     (ZP_STRING_BUFFER), y
    beq     @end

    sta     ACIA_DATA
    lda     #$FF
@b0:
    dec
    bne     @b0
    iny

    bra     @loop

@end:       
    rts

.export     acia_irq
acia_irq:   
    lda     #$FF
    sta     VIA_PORTA
    sta     VIA_PORTB

@poll:                                  ;
    lda     ACIA_STATUS                 ;
    bit     #$08                        ;   Poll until the byte can be read
    beq     @poll                       ;
    lda     ACIA_DATA                   ;

    ldx     IB_IDX
    sta     IB_BASE, x

    cmp     #$0D                        ;
    beq     @CR                         ;   CR?

    cmp     #$7F                        ;
    beq     @DEL                        ;
    cmp     #$08                        ;   DEL or BS?
    beq     @DEL                        ;

    jsr     _uart_write_byte            ;
    inx                                 ;
    bra     @end                        ;

@CR:                                    ;
    stz     IB_READY                    ;
    jsr     _uart_write_byte            ;   Input buffer can be read by the running program
    lda     #$0A                        ;   
    jsr     _uart_write_byte            ;
    stx     IB_IDX_TMP                  ;   Store the current index for later use
    ldx     #$00                        ;   Reset the input buffer index
@DEL:
    txa                                 ;
    beq     @end                        ;   check if input buffer is already zero
    dex                                 ;

    lda     #$08                        ;
    jsr     _uart_write_byte            ;   send backspace
    lda     #$20                        ;
    jsr     _uart_write_byte            ;   send space
    lda     #$08                        ;
    jsr     _uart_write_byte            ;   send backspace
@end:
    stx     IB_IDX

    rts

.export     via_irq
via_irq:    
    pha
    pla
    rts
