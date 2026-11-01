;
;   File:           vectors.s
;   Description:    The NMI, RESET and IRQ vectors
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       01.11.2026
;   Version:        0.0.1
;   


.include    "./inc/memory.inc"
.include    "./inc/peripherals.inc"
.include    "./inc/games.inc"
.include    "./inc/monitor.inc"
.include    "./inc/program.inc"
.include    "./inc/utils.inc"

.feature string_escapes

.rodata
msg_sys_init:
.asciiz "\n\rMicro6502 v1.0\n\rCopyright 2026 Morosanu Nicolas. All rights reserved.\n\r\n\r"

msg_sys_invalid_cmd:
.asciiz "Invalid command!\n\r"

msg_prompt:
.asciiz "\n\r > "

.code
.export NMI
NMI:
    rti

.export RESET
RESET:      
    sei                                     ;
    ldx     #$FF                            ;   
    txs                                     ;   init stiva
    cld                                     ;   decimal mode dezactivat
    
    stz     IB_IDX
    stx     IB_READY
    lda     #$AA
    sta     PRNG_SEED
    sta     PRNG_VAL_MAX

    jsr     sys_peripherals_config

    lda     #<msg_sys_init
    sta     ZP_STRING_BUFFER
    lda     #>msg_sys_init
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

    cli
HOME:
    sei                                     ;
    ldx     #$FF                            ;
    txs                                     ;
    cli                                     ;

    lda     #<msg_prompt
    sta     ZP_STRING_BUFFER
    lda     #>msg_prompt
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    ;
    ;   reinitialize vars
    ;
@loop_ib_ready:                             ;
    lda     IB_READY                        ;   Asteapta pana cand avem o comanda.
    bne     @loop_ib_ready                  ;
@parse:
    sei                                     ;
    ldx     #$FF                            ;
    txs                                     ;   Reset stiva.
    cli                                     ;

    dec     IB_READY                        ;   

    lda     IB_BASE
    cmp     #'m'                            ;   If first char is m,
    beq     @monitor                        ;   launch memory monitor.
    cmp     #'g'                            ;   If first char is g,
    beq     @games                          ;   check for games.

    lda     #<msg_sys_invalid_cmd           ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_sys_invalid_cmd           ;   Semnaleaza comanda invalida.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    bra     HOME                            ;   return.

@monitor:
    jmp     _monitor_init

@games:                                     ;
    lda     IB_BASE + 1                     ;   Retrieve next byte.
    cmp     #'h'                            ;   If char is h,
    beq     @hangman                        ;   launch hangman.
    cmp     #'b'                            ;   If char is m
    beq     @blackjack                      ;   launch blackjack.
    
    lda     #<msg_sys_invalid_cmd           ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_sys_invalid_cmd           ;   Semnaleaza comanda invalida.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    dec     IB_READY                        ;
    bra     @loop_ib_ready                  ;   return.

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
.word   HOME
.word   NMI
.word   RESET
.word   IRQ
