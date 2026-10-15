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
    
    lda     #$AA
    sta     PRNG_SEED
    stx     IB_READY

    dex
    stx     VIA_PORTA
    stx     VIA_PORTB

    jsr     _peripherals_config

    cli

mainloop:
    lda     IB_READY
    beq     @parse
    bra     mainloop
@parse:
    ldx     #$FF                            ;
    txs                                     ;   reset stack for the loaded mode

    lda     IB_BASE
    cmp     #'p'                            ;   if first char is p
    beq     @program                        ;   launch program mode
    cmp     #'m'                            ;   if first char is m,
    beq     @monitor                        ;   launch memory monitor
    cmp     #'g'                            ;   if first char is g,
    beq     @games                          ;   check for games

    dec     IB_READY                        ;   nothing matched,
    bra     mainloop                        ;   return to mainloop

@program:
    jmp     _program_init

@monitor:
    jmp     _monitor_init

@games:                                     ;
    lda     IB_BASE + 1                     ;   retrieve next byte
    cmp     #'h'                            ;   if char is h,
    beq     @hangman                        ;   launch hangman
    cmp     #'m'                            ;   if char is m
    beq     @minesweeper                    ;   launch minesweeper

    dec     IB_READY                        ;   nothing matched,
    bra     mainloop                        ;   return to mainloop
@hangman:
    jmp     _hangman_init
@minesweeper:
    jmp     _minesweeper_init

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
.word NMI
.word RESET
.word IRQ
