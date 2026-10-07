.include    "./inc/memory.inc"
.include    "./inc/peripherals.inc"
.include    "./inc/games.inc"
.include    "./inc/monitor.inc"
.include    "./inc/program.inc"

.rodata
.code

.export NMI
NMI:
    rti

.export RESET
RESET:      
    sei                                 ;
    ldx     #$FF                        ;
    txs                                 ;   init stack and peripherals
    cld                                 ;
    jsr     _peripherals_config         ;
    jsr     ram_clear
    cli                                 ;

    stz     $00 + $50

    lda     #'g'
    sta     ib_base

@loop:
    bbr0    $00 + $50, @loop

@ib_parse:
    lda     ib_base

    cmp     #'p'
    beq     @program
    cmp     #'m'
    beq     @monitor
    cmp     #'g'
    beq     @games
    bra     @loop

@program:   jmp     program
@monitor:   jmp     monitor
@games:     jmp     games

program:
    ldx     #$FF
    txs
    jmp     program_init
@hang:
    bra     @hang

monitor:
    ldx     #$FF
    txs
    jmp     monitor_init
@hang:
    bra     @hang

games:
    ldx     #$FF
    txs

    ldx     #$01
    lda     ib_base, x
    cmp     #'m'
    beq     @minesweeper
    cmp     #'h'
    beq     @hangman
    bra     @hang
@minesweeper:
    jmp     minesweeper_init
@hangman:
    jmp     hangman_init
@hang:
    bra     @hang

.export IRQ
IRQ:
    pha
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

brk_irq:
    pha
    pla
    rts

ram_clear:
    lda     #$10
    sta     $00 + 1
    lda     #$00
    sta     $00 

    lda     #$00
@loop:
    sta     ($00)
    inc     $00 
    bne     @loop

    inc     $00 + 1
    ldx     $00 + 1
    cpx     #$80
    bne     @loop

    rts

;   disabled while debugging with sim65
;.segment "VECTORS"
;.word NMI
;.word RESET
;.word IRQ
