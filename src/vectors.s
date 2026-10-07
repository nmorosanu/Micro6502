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
    sei
    ldx     #$FF
    txs
    cld

    jsr     _peripherals_config         ;

;    stz     $00                         ;
;    lda     #$10                        ;
;    sta     $01                         ;
;    lda     #$A5                        ;
;@ram_clear_loop:                        ;   Reset RAM
;    sta     ($00)                       ;   (writes xA5 in all of the systems RAM locations)
;    inc     $00                         ;
;    bne     @loop                       ;
;    inc     $01                         ;
;    ldx     $01                         ;
;    cpx     #$80                        ;
;    bne     @ram_clear_loop             ;

    cli

halt:
    bra     halt

.export ib_parse
ib_parse:
    lda     IB_BASE

    cmp     #'p'
    beq     @program
    cmp     #'m'
    beq     @monitor
    cmp     #'g'
    beq     @games
    bra     halt

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
    lda     IB_BASE, x
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


;   disabled while debugging with sim65
.segment "VECTORS"
.word NMI
.word RESET
.word IRQ
