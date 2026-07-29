.include    "../inc/memory.inc"
.include    "../inc/peripherals.inc"

.rodata
.code
.export     NMI
NMI:
            rti

.export     RESET
RESET:      sei                                 ;
            ldx     #$FF                        ;
            txs                                 ;   init stack and peripherals
            cld                                 ;
            jsr     peripherals_config          ;
            jsr     ram_clear
            cli                                 ;

            stz     zp_tmp + $50

            lda     #'g'
            sta     ib_base

@loop:      bbr0    zp_tmp + $50, @loop

@ib_parse:  lda     ib_base
            ldx     ib_idx

            cmp     #'p'
            beq     @program
            cmp     #'m'
            beq     @monitor
            cmp     #'g'
            beq     @games
            ;       undefined cmd
            bra     @loop
@program:   jmp     program
@monitor:   jmp     monitor
@games:     jmp     games

program:    ldx     #$FF
            txs
@hang:      bra     @hang

monitor:    ldx     #$FF
            txs
@hang:      bra     @hang

games:      ldx     #$FF
            txs
@hang:      bra     @hang

.export     IRQ
IRQ:        pha
            phx

            tsx
            lda     $0103, x
            bit     #$10
            beq     @brk

            lda     ACIA_STATUS
            bmi     @acia
            lda     VIA_IFR
            bmi     @via

            bra     @end
@brk:
            jsr     brk_irq
            bra     @end
@acia:
            jsr     acia_irq
            bra     @end
@via:
            jsr     via_irq
            bra     @end
@end:
            plx
            pla

            rti

brk_irq:    pha

            pla
            rts

ram_clear:  lda     #$10
            sta     zp_tmp + 1
            lda     #$00
            sta     zp_tmp

            lda     #$00
@loop:      sta     (zp_tmp)
            inc     zp_tmp
            bne     @loop

            inc     zp_tmp + 1
            ldx     zp_tmp + 1
            cpx     #$80
            bne     @loop

            rts
