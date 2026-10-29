;
;   File:           blackjack.s
;   Description:    Blackjack game over UART.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       29.10.2026
;   Version:        0.0.1
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"
.include "inc/utils.inc"

.rodata
cards:
    .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
    .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
    .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
    .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
    ;     A  2  3  4  5  6  7  8  9  10,  J,  Q,  K

_bj_msg_init:
    .asciiz "BLACKJACK INIT"

_bj_msg_prompt:
    .asciiz "HIT or STAY? (h / s): "

_bj_msg_err_command_invalid:
    .asciiz "ERR: Invalid command\n\r"

_bj_msg_win:
    .asciiz "You win!\n\r"

_bj_msg_lose:
    .asciiz "You lose!\n\r"

_bj_msg_tie:
    .asciiz "Tie!\n\r"

.data
PLAYER_HAND_TOTAL   =   $00
SYSTEM_HAND_TOTAL   =   $01
SHUFFLE_I           =   $02
SHUFFLE_J           =   $03
TMP                 =   $04
DECK_POS            =   $05
DECK_BASE           =   $3000

.code
.export _blackjack_init
_blackjack_init:
@reset:
    lda     #<_bj_msg_init
    lda     #>_bj_msg_init
    jsr     func_uart_string_write

    jsr     func_deck_init
    
    lda     DECK_BASE                       ;
    adc     DECK_BASE + 1                   ;   Deal two random cards to the system
    sta     SYSTEM_HAND_TOTAL               ;

    lda     DECK_BASE + 2                   ;
    adc     DECK_BASE + 3                   ;   Deal two random cards to the player
    sta     PLAYER_HAND_TOTAL               ;

    lda     #$04
    sta     DECK_POS
    
@loop:
    lda     #<_bj_msg_prompt
    lda     #>_bj_msg_prompt
    jsr     func_uart_string_write
    ;
    ;   print stats and wait for input
    ;
@wait:
    lda     IB_READY
    bne     @wait

    
    lda     IB_BASE
    cmp     #'s'
    beq     @stay
    cmp     #'h'
    beq     @hit
    lda     #<_bj_msg_err_command_invalid
    lda     #>_bj_msg_err_command_invalid
    jsr     func_uart_string_write
    bra     @loop
@stay:
@system_loop:
    lda     SYSTEM_HAND_TOTAL
    cmp     #17
    bcs     @system_loop_end
    jsr     func_hit
    adc     SYSTEM_HAND_TOTAL
    sta     SYSTEM_HAND_TOTAL
    bra     @system_loop
@system_loop_end:
    cmp     PLAYER_HAND_TOTAL
    bcc     @player_win
    bcs     @system_win
    bra     @tie
@tie:
    lda     #<_bj_msg_tie
    lda     #>_bj_msg_tie
    jsr     func_uart_string_write
    bra     @reset
@system_win:
    lda     #<_bj_msg_lose
    lda     #>_bj_msg_lose
    jsr     func_uart_string_write
    bra     @reset

@player_win:
    lda     #<_bj_msg_win
    lda     #>_bj_msg_win
    jsr     func_uart_string_write
    bra     @reset

@hit:
    jsr     func_hit
    adc     PLAYER_HAND_TOTAL
    sta     PLAYER_HAND_TOTAL
    cmp     #21
    bcs     @system_win
    beq     @skip
@skip:
    bra     @loop

func_deck_init:
    pha
    phx

    lda     #$51
    sta     PRNG_VAL_MAX

    ldx     #$00
@loop0:
    txa
    sta     DECK_BASE, X
    inx
    cpx     #$51
    bne     @loop0
    stz     DECK_BASE
    
    lda     #51
    sta     SHUFFLE_I
@shuffle:
    lda     SHUFFLE_I
    jsr     func_rng
    sta     SHUFFLE_J
    
    ldx     SHUFFLE_I
    lda     DECK_BASE, X
    sta     TMP

    ldx     SHUFFLE_J
    lda     DECK_BASE, X
    ldx     SHUFFLE_I
    sta     DECK_BASE, X

    ldx     SHUFFLE_J
    lda     TMP
    sta     DECK_BASE, X

    dec     SHUFFLE_I
    bne     @shuffle

    plx
    pla
    rts

func_hit:
    phx
    ldx     DECK_POS
    lda     DECK_BASE, X
    inx
    stx     DECK_POS
    plx
    rts
