;
;   File:           vectors.s
;   Description:    The NMI, RESET and IRQ vectors
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       29.10.2026
;   Version:        0.0.1
;   

.include    "./inc/memory.inc"
.include    "./inc/peripherals.inc"
.include    "./inc/games.inc"
.include    "./inc/monitor.inc"
.include    "./inc/program.inc"
.include    "./inc/utils.inc"

.code
.export NMI
NMI:
    rti

.export RESET
RESET:      
    sei
    ldx     #$FF
    txs
    cld
    
    stx     IB_READY
    
    lda     #$AA
    sta     PRNG_SEED
    sta     PRNG_VAL_MAX

    jsr     sys_peripherals_config

    cli

mainloop:
    lda     IB_READY
    beq     @parse
    bra     mainloop
@parse:
    ldx     #$FF                            ;
    txs                                     ;   Reset stack for the loaded mode.

    lda     IB_BASE
    cmp     #'m'                            ;   If first char is m,
    beq     @monitor                        ;   launch memory monitor.
    cmp     #'g'                            ;   If first char is g,
    beq     @games                          ;   check for games.

    dec     IB_READY                        ;   Nothing matched,
    bra     mainloop                        ;   return to mainloop.

@monitor:
    jmp     _monitor_init

@games:                                     ;
    lda     IB_BASE + 1                     ;   Retrieve next byte.
    cmp     #'h'                            ;   If char is h,
    beq     @hangman                        ;   launch hangman.
    cmp     #'b'                            ;   If char is m
    beq     @blackjack                      ;   launch blackjack.

    dec     IB_READY                        ;   Nothing matched,
    bra     mainloop                        ;   return to mainloop.
@hangman:
    jmp     _hangman_init
@blackjack:
    jmp     _blackjack_init

.export IRQ
IRQ:
    pha
    phx

    lda     ACIA_STATUS
    bmi     @acia
    lda     VIA_IFR
    bmi     @via
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

brk_irq:
    rts


;   disabled while debugging with sim65
.segment "VECTORS"
;.word NMI
;.word RESET
;.word IRQ
