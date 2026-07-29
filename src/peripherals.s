.include    "../inc/memory.inc"

.code
.export     peripherals_config
peripherals_config:
            ;       VIA CONFIGURATION
            lda     #$FF
            sta     VIA_DDRA            ;
            stz     VIA_PORTA           ;
            sta     VIA_DDRB            ;   PORTA = PORTB = x00
            stz     VIA_PORTB           ;

            ;       ACIA CONFIGURATION
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
            jsr     lcd_wcmd            ;

            lda     #$28                ;
            jsr     lcd_wcmd            ;

            lda     #$06                ;
            jsr     lcd_wcmd            ;

            lda     #$0C                ;
            jsr     lcd_wcmd            ;

            lda     #$01                ;
            jsr     lcd_wcmd            ;
            lda     #$80                ;
            jsr     lcd_wcmd            ;   CLEAR

            rts

.export     lcd_dly
lcd_dly:    pha
            lda     #$30

@loop:      dec
            bne     @loop

            pla
            rts

.export     lcd_clr
lcd_clr:    pha
            lda     #$01
            jsr     lcd_wcmd
            lda     #$80
            jsr     lcd_wcmd
            pla
            rts

.export     lcd_wcmd
lcd_wcmd:   pha

            sta     zp_tmp
            and     #$F0
            ora     #$08
            sta     VIA_PORTB

            jsr     lcd_dly

            and     #$F0
            sta     VIA_PORTB

            jsr     lcd_dly

            lda     zp_tmp
            rol
            rol
            rol
            rol
            and     #$F0
            ora     #$08
            sta     VIA_PORTB

            jsr     lcd_dly

            and     #$F0
            sta     VIA_PORTB

            jsr     lcd_dly

            pla
            rts

.export     lcd_wchr
lcd_wchr:   pha

            sta     zp_tmp
            and     #$F0
            ora     #$0C
            sta     VIA_PORTB

            jsr     lcd_dly

            and     #$F4
            sta     VIA_PORTB

            jsr     lcd_dly

            lda     zp_tmp
            rol
            rol
            rol
            rol
            and     #$F0
            ora     #$0C
            sta     VIA_PORTB

            jsr     lcd_dly

            and     #$F4
            sta     VIA_PORTB

            jsr     lcd_dly

            pla
            rts

.export     lcd_wstr
lcd_wstr:   pha
            phy
            
            sta     zp_str_buffer
            sty     zp_str_buffer + 1
            ldy     #$00

@loop:      lda     (zp_str_buffer), y
            beq     @end

            jsr     lcd_wchr
            iny

            bra     @loop

@end:       ply
            pla
            rts

.export     uart_rb
uart_rb:    pha
@poll:      lda     ACIA_STATUS
            bit     #$08
            beq     @poll

            lda     ACIA_DATA
    
            rts

.export     uart_wb
uart_wb:    sta     ACIA_DATA
            pha
            lda     #$FF
@b0:        dec
            bne     @b0
            rts

.export     acia_irq
acia_irq:   pha
            phx

            jsr     uart_rb

            ldx     ib_base
            sta     ib_base, x
        
            cmp     #$0D                ;   CR?
            beq     @CR

            jsr     uart_wb
            inx
            bra     @end

@CR:        jsr     uart_wb
            lda     #$0A
            jsr     uart_wb
            ldx     #$00
@end:
            stx     ib_idx
            plx
            pla

            rts


.export     via_irq
via_irq:    pha
            pla
            rts
