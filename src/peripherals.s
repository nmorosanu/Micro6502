;
;   File:           peripherals.s
;   Description:    A collection of subroutines for managing the system's peripherals 
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       31.10.2026
;   Version:        0.0.1
;   

.include    "./inc/memory.inc"

.code
.export sys_peripherals_config
sys_peripherals_config:
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
    ;jsr     _lcd_init

    rts

.export sys_lcd_init
sys_lcd_init:
    jsr     sys_lcd_delay
    lda     #$33                    ;
    jsr     sys_lcd_command        ;
    lda     #$32                    ;
    jsr     sys_lcd_command        ;
    lda     #$28                    ;
    jsr     sys_lcd_command        ;
    lda     #$0C                    ;
    jsr     sys_lcd_command        ;
    lda     #$06                    ;
    jsr     sys_lcd_command        ;
    lda     #$01                    ;
    jsr     sys_lcd_command        ;
    lda     #$80                    ;
    jsr     sys_lcd_command        ;
    rts

.export     sys_lcd_delay
sys_lcd_delay:   
    ldx     #$FF
@dx:
    dex
    bne     @dx
    rts

.export sys_lcd_clear
sys_lcd_clear:
    pha
    lda     #$01
    jsr     sys_lcd_command
    lda     #$80
    jsr     sys_lcd_command
    pla
    rts

.export sys_lcd_command
sys_lcd_command:
    sta     $00
    and     #$F0
    ora     #$08
    sta     VIA_PORTB

    jsr     sys_lcd_delay

    and     #$F0
    sta     VIA_PORTB

    jsr     sys_lcd_delay

    lda     $00
    rol
    rol
    rol
    rol
    and     #$F0
    ora     #$08
    sta     VIA_PORTB

    jsr     sys_lcd_delay

    and     #$F0
    sta     VIA_PORTB

    jsr     sys_lcd_delay

    rts

.export sys_lcd_byte_write
sys_lcd_byte_write:
    sta     $00
    and     #$F0
    ora     #$0C
    sta     VIA_PORTB

    jsr     sys_lcd_delay

    and     #$F4
    sta     VIA_PORTB

    jsr     sys_lcd_delay

    lda     $00
    rol
    rol
    rol
    rol
    and     #$F0
    ora     #$0C
    sta     VIA_PORTB

    jsr     sys_lcd_delay

    and     #$F4
    sta     VIA_PORTB

    jsr     sys_lcd_delay
    lda     $00

    rts

.export sys_lcd_string_write
sys_lcd_string_write:  
    ldy     #$00
@loop:      lda     (ZP_STRING_BUFFER), y
    beq     @end

    jsr     sys_lcd_byte_write
    iny

    bra     @loop

@end:       
    rts

.export sys_uart_byte_read
sys_uart_byte_read:
    pha
@poll:
    lda     ACIA_STATUS
    bit     #$08
    beq     @poll

    lda     ACIA_DATA

    rts

.export sys_uart_byte_write
sys_uart_byte_write:   
    sta     ACIA_DATA
    pha
    lda     #$FF
@b0:
    dec
    bne     @b0
    pla
    rts

.export sys_uart_string_write
sys_uart_string_write:
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

    jsr     sys_uart_byte_write        ;
    inx                                 ;
    bra     @end                        ;

@CR:                                    ;
    stz     IB_READY                    ;
    jsr     sys_uart_byte_write            ;   Input buffer can be read by the running program
    lda     #$0A                        ;   
    jsr     sys_uart_byte_write            ;
    stx     IB_IDX_TMP                  ;   Store the current index for later use
    ldx     #$00                        ;   Reset the input buffer index
@DEL:
    txa                                 ;
    beq     @end                        ;   check if input buffer is already zero
    dex                                 ;

    lda     #$08                        ;
    jsr     sys_uart_byte_write            ;   send backspace
    lda     #$20                        ;
    jsr     sys_uart_byte_write            ;   send space
    lda     #$08                        ;
    jsr     sys_uart_byte_write            ;   send backspace
@end:
    stx     IB_IDX

    rts

.export     via_irq
via_irq:    
    pha
    pla
    rts
