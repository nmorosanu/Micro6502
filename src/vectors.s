.include    "./inc/memory.inc"
.include    "./inc/peripherals.inc"
.include    "./inc/games.inc"
.include    "./inc/monitor.inc"
.include    "./inc/program.inc"
.include    "./inc/crc.inc"

.rodata
str: .asciiz "abcdefghijklmn"

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

    jsr     _peripherals_config

    cli
    lda     #<str   
    sta     ZP_STRING_BUFFER
    lda     #>str   
    sta     ZP_STRING_BUFFER + 1

    jsr     crc16clc                     ; xA8E1
    lda     CRC
    ldx     CRC + 1

    stp

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
;.word NMI
;.word RESET
;.word IRQ
