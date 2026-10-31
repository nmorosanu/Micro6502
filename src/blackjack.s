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
cards:  .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
        .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
        .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
        .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10
    ;     A  2  3  4  5  6  7  8  9  10,  J,  Q,  K

msg_init:
.asciiz "\n\rBLACKJACK GAME\n\rBoth you and the computer draw 2 cards at first.\n\rType 'h' to print the help menu.\n\r"

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
DRAWING_DONE    =   $02     ;   
QUIT            =   $03     ;   semnaleaza dorinta de a opri programul.
TMP0            =   $04
DECK_POS        =   $0A     ;   pozitia in pachetul de carti
DECK_BASE       =   $7FCB   ;   ultimele 52 de pozitii din RAM sunt pachetul de carti

.code
.export _blackjack_init
_blackjack_init:
    lda     #<msg_init                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_init                      ;   Afiseaza mesaj de initializare
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

@loop:                                      ;
    jsr     _blackjack_loop                 ;
    lda     QUIT                            ;
    beq     @loop
    jmp     ($FFF8)                         ;   Salt la "HOME".

_blackjack_loop:
    jsr     _blackjack_deck_shuffle         ;   Amesteca pachetul.

    stz     QUIT                            ;
    stz     DRAWING_DONE                    ;   Reseteaza variabilele
    stz     DECK_POS                        ;
    stz     TMP0                            ;

    lda     #$00                            ;
    jsr     _blackjack_draw                 ;
    jsr     _blackjack_draw                 ;   Computerul primeste 2 carti.
    sta     HAND_COMPUTER                   ;

    lda     #$00                            ;
    jsr     _blackjack_draw                 ;
    jsr     _blackjack_draw                 ;   Jucatorul primeste 2 carti.
    sta     HAND_PLAYER                     ;
@loop:
    lda     #<msg_stats                     ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_stats                     ;   Afiseaza mesajul stats.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    lda     HAND_PLAYER                     ;
    jsr     NUM2STR                         ;
    lda     #<NUM2STR                       ;
    sta     ZP_STRING_BUFFER                ;   Afiseaza scorul jucatorului.
    lda     #>NUM2STR                       ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    lda     #<msg_prompt                    ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_prompt                    ;   Afiseaza prompt.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

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
    pha
    phx
    phy

    ldx     #00
@loop:
    txa                                     ;
    inc                                     ;
    sta     PRNG_VAL_MAX                    ;
    jsr     sys_prng                        ;
    tay                                     ;   Y = sys_prng(0, i + 1)

    lda     DECK_BASE, X                    ;
    sta     TMP0                            ;   TMP0 = deck[i]

    lda     DECK_BASE, Y                    ;
    sta     DECK_BASE, X                    ;   deck[i] = deck[j]

    lda     TMP0                            ;
    sta     DECK_BASE, Y                    ;   deck[j] = TMP0

    inx                                     ;
    cpx     #52                             ;   itereaza peste toate cartile din pachet [0, 51]
    bne     @loop                           ;

    ply
    plx
    pla
    rts

_blackjack_buffer_parse:
    pha

    lda     IB_BASE                         ;
    cmp     #'d'                            ;
    beq     @draw                           ;
    cmp     #'s'                            ;   
    beq     @stay                           ;   Identifica comanda.
    cmp     #'h'                            ;
    beq     @help                           ;
    cmp     #'q'                            ;
    beq     @quit                           ;

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
    cpx     #52                             ;   if (x == 52)
    bne     @continue                       ;       x = 0;
    stz     DECK_POS                        ;
    ldx     DECK_POS
@continue:                                  ;
    clc                                     ;
    adc     DECK_BASE, X                    ;   A = A + deck[x];
    inx
    stx     DECK_POS

    plx
    rts

_blackjack_stay:
    pha
    phx

    clc
    lda     HAND_COMPUTER                   ;   A = HAND_COMPUTER
@loop:                                      ;
    cmp     #17                             ;
    bcc     @end                            ;   while (A < 17) {
    jsr     _blackjack_draw                 ;       A = A + _blackjack_draw;
    bra     @loop                           ;   }
@end:                                       ;
    sta     HAND_COMPUTER                   ;   HAND_COMPUTER = A

    plx
    pla
    rts

_blackjack_help:
    lda     #<msg_help                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_help                      ;   Afiseaza mesaj help.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    rts

_blackjack_quit:
    lda     #<msg_quit                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_quit                      ;   Afiseaza mesaj quit
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    inc     QUIT                            ;   Quit = 1 -> salt la "HOME"

    rts
