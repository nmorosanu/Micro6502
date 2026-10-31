;
;   File:           blackjack.s
;   Description:    Blackjack game over UART.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       31.10.2026
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

msg_error:
.asciiz "\n\rInvalid action. Type 'h' for help\n\r"

msg_help:
.asciiz "\n\n\rBLACKJACK HELP MENU\n\n\rFor drawing cards, type 'd'\n\rFor staying, type 's'\n\n\r" 

msg_stats:
.asciiz "\n\rComputer's hand -> ???\n\rYour hand       -> "

msg_results:
.asciiz "\n\rResults -> \n\r"

msg_prompt:
.asciiz "Action > "

msg_quit:
.asciiz "\n\rQuitting...\n\r"

msg_cw_pb:
.asciiz "\n\rComputer won. Player busted.\n\r"

msg_pw_cb:
.asciiz "\n\rYou won! Computer busted.\n\r"

msg_pw:
.asciiz "\n\rYou won!\n\r"

msg_pl:
.asciiz "\n\rYou lost! Computer won.\n\r"

msg_tie:
.asciiz "\n\rTie.\n\r"

.data
HAND_PLAYER     =   $00     ;   valoarea acumulata de jucator
HAND_COMPUTER   =   $01     ;   valoarea acumulata de computer
TMP0            =   $02
TMP1            =   $03
TMP2            =   $04
TMP3            =   $05
DRAWING_DONE    =   $06     ;   
QUIT            =   $07     ;   semnaleaza dorinta de a opri jocul.

DECK_POS        =   $0F     ;   pozitia in pachetul de carti
DECK_BASE       =   $7FCB   ;   ultimele 52 de pozitii din RAM sunt pachetul de carti

.code
.export _blackjack_init
_blackjack_init:
@loop:
    jsr     _blackjack_loop
    lda     QUIT
    beq     @loop
    jmp     ($FFF8)                         ;   return home

_blackjack_loop:
    jsr     _blackjack_deck_shuffle         ;   amesteca pachetul
    stz     QUIT
    stz     DRAWING_DONE
    stz     DECK_POS

    lda     #$00
    jsr     _blackjack_draw
    jsr     _blackjack_draw
    sta     HAND_COMPUTER

    lda     #$00
    jsr     _blackjack_draw
    jsr     _blackjack_draw
    sta     HAND_PLAYER
@loop:
    lda     #<msg_stats
    sta     ZP_STRING_BUFFER
    lda     #>msg_stats
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    ;
    ;       afisare player's hand
    ;
    lda     #<msg_prompt
    sta     ZP_STRING_BUFFER
    lda     #>msg_prompt
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

@loop_action:
    lda     IB_READY
    bne     @loop_action

    jsr     _blackjack_buffer_parse

    lda     DRAWING_DONE
    bne     @loop
    
    clc
    lda     HAND_PLAYER
    cmp     #22
    bcs     @player_bust
    lda     HAND_COMPUTER
    cmp     #22
    bcs     @computer_bust
    lda     HAND_PLAYER
    cmp     HAND_COMPUTER
    bcc     @player_lost
    beq     @tie

    lda     #<msg_pw
    sta     ZP_STRING_BUFFER
    lda     #>msg_pw
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

@player_bust:
    lda     #<msg_cw_pb
    sta     ZP_STRING_BUFFER
    lda     #>msg_cw_pb
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
@computer_bust:
    lda     #<msg_pw_cb
    sta     ZP_STRING_BUFFER
    lda     #>msg_pw_cb
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
@player_lost:
    lda     #<msg_pl
    sta     ZP_STRING_BUFFER
    lda     #>msg_pl
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
@tie:
    lda     #<msg_tie
    sta     ZP_STRING_BUFFER
    lda     #>msg_tie
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

    lda     #<msg_results
    sta     ZP_STRING_BUFFER
    lda     #>msg_results
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    ;
    ;   also print the actual results
    ;
    rts

_blackjack_deck_shuffle:
    rts

_blackjack_buffer_parse:
    pha
    lda     IB_BASE
    cmp     #'d'
    beq     @draw
    cmp     #'s'
    beq     @stay
    cmp     #'h'
    beq     @help
    cmp     #'q'
    beq     @quit

    lda     #<msg_error                     ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_error                     ;   Semnaleaza eroarea in caz ca nu s-a
    sta     ZP_STRING_BUFFER + 1            ;   gasit o comanda valida.
    jsr     sys_uart_string_write           ;

    bra     @end
@draw:
    jsr     _blackjack_draw
    bra     @end
@stay:
    jsr     _blackjack_stay
    bra     @end
@help:
    jsr     _blackjack_help
    bra     @end
@quit:
    jsr     _blackjack_quit
@end:
    pla
    rts

;
;
;   returns value in A
_blackjack_draw:
    phx

    ldx     DECK_POS                        ;
    cpx     #52                             ;   Daca pozitia a ajuns la 52, reseteaz-o la 0.
    bne     @continue                       ;
    stz     DECK_POS                        ;
    ldx     DECK_POS
@continue:
    clc
    adc     DECK_BASE, X
    inx
    stx     DECK_POS

    plx
    rts

_blackjack_stay:
    pha
    phx

    clc
    lda     HAND_COMPUTER
@loop:
    cmp     #17
    bcc     @end

    jsr     _blackjack_draw

    bra     @loop
@end:
    sta     HAND_COMPUTER

    plx
    pla
    rts

_blackjack_help:
    lda     #<msg_help
    sta     ZP_STRING_BUFFER
    lda     #>msg_help
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    rts

_blackjack_quit:
    lda     #<msg_quit
    sta     ZP_STRING_BUFFER
    lda     #>msg_quit
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

    inc     QUIT

    rts
