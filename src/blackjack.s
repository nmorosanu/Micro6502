;
;   File:           blackjack.s
;   Description:    Blackjack game over UART.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       01.11.2026
;   Version:        1.0.0
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"
.include "inc/utils.inc"

.feature string_escapes

.rodata
cards:  .byte 1, 2, 5, 4, 3, 6, 7, 8, 9, 10, 10, 10, 10
        .byte 10, 10, 10, 5, 6, 8, 7, 4, 3, 9, 10, 2, 1
        .byte 1, 2, 10, 9, 3, 4, 7, 8, 6, 5, 10, 10, 10
        .byte 10, 10, 10, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1

msg_init:
.asciiz "\n\rBLACKJACK GAME\n\rBoth you and the computer draw 2 cards at first.\n\rType 'h' to print the help menu.\n\r"

msg_error:
.asciiz "Invalid action. Type 'h' for help\n\r"

msg_help:
.asciiz "\n\r* BLACKJACK HELP MENU\n\r* d -> draw new card\n\r* s -> stay\n\r* q -> quit program\n\r" 

msg_stats:
.asciiz "Computer's hand -> ???\n\rYour hand       -> "

msg_results_part1:
.asciiz "+---------------+\n\r     RESULTS     \n\r       YOU - "

msg_results_part2:
.asciiz "\n\r  COMPUTER - "

msg_results_part3:
.asciiz "\n\r+---------------+\n\r"

msg_prompt:
.asciiz "\n\rAction > "

msg_quit:
.asciiz "Quitting...\n\r"

msg_shuffling:
.asciiz "Shuffling cards...\n\r"

msg_cw_pb:
.asciiz "  Player busted\n\r"

msg_pw_cb:
.asciiz " Computer busted\n\r"

msg_pw:
.asciiz "    You WIN\n\r"

msg_pl:
.asciiz "    You LOST\n\r"

msg_tie:
.asciiz "  *    TIE    *\n\r"

.data
HAND_COMPUTER   =   $00     ;   valoarea acumulata de computer
DRAWING_DONE    =   $01     ;   
HAND_PLAYER     =   $02     ;   valoarea acumulata de jucator
TMP0            =   $03
TMP1            =   $04
DECK_POS        =   $05     ;   pozitia in pachetul de carti
DECK_BASE       =   $7FCB   ;   ultimele 52 de pozitii din RAM sunt pachetul de carti
;7FCB

.code
.export _blackjack_init
_blackjack_init:
    lda     #$5A
    sta     PRNG_SEED

    lda     #<msg_init                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_init                      ;   Afiseaza mesaj de initializare
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
@mainloop:
    stz     DRAWING_DONE                    ;   Reseteaza variabilele
    stz     DECK_POS                        ;

    jsr     _blackjack_deck_shuffle         ;   Amesteca pachetul.

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
    jsr     sys_num2str                     ;
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
    beq     @loop

    jsr     _blackjack_results

    bra     @mainloop

_blackjack_results:
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
    bra     @results

@player_bust:
    lda     #<msg_cw_pb
    sta     ZP_STRING_BUFFER
    lda     #>msg_cw_pb
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    bra     @results

@computer_bust:
    lda     #<msg_pw_cb
    sta     ZP_STRING_BUFFER
    lda     #>msg_pw_cb
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    bra     @results

@player_lost:
    lda     #<msg_pl
    sta     ZP_STRING_BUFFER
    lda     #>msg_pl
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    bra     @results

@tie:
    lda     #<msg_tie
    sta     ZP_STRING_BUFFER
    lda     #>msg_tie
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

@results:
    lda     #<msg_results_part1             ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_results_part1             ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    lda     HAND_PLAYER                     ;   Afiseaza scorul jucatorului.
    jsr     sys_num2str                     ;
    lda     #<NUM2STR                       ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>NUM2STR                       ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    lda     #<msg_results_part2             ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_results_part2             ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    lda     HAND_COMPUTER                   ;   Afiseaza scorul computerului.
    jsr     sys_num2str                     ;
    lda     #<NUM2STR                       ;
    sta     ZP_STRING_BUFFER                ;   
    lda     #>NUM2STR                       ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    lda     #<msg_results_part3             ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_results_part3             ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    rts

_blackjack_deck_shuffle:
    pha
    phx
    phy

    lda     #<cards                         ;
    sta     TMP0                            ;
    lda     #>cards                         ;
    sta     TMP1                            ; TMP0 + 1

    lda     #<msg_shuffling                 ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_shuffling                 ;  Afiseaza mesaj.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    ldy     #$00
@copy:
    lda     (TMP0), Y
    sta     DECK_BASE, Y
    
    iny
    cpy     #52
    bne     @copy

    ldx     #$01
@shuffle:
    txa                                     ;
    sta     PRNG_VAL_MAX                    ;
    jsr     sys_prng                        ;
    tay                                     ;   Y = sys_prng(0, X)

    lda     DECK_BASE, Y                    ;
    sta     TMP0                            ;   TMP0 = DECK_BASE[Y];

    lda     DECK_BASE, X                    ;
    sta     DECK_BASE, Y                    ;   DECK_BASE[Y] = DECK_BASE[X]

    lda     TMP0                            ;
    sta     DECK_BASE, X                     ;   DECK_BASE[X] = TMP0

    inx
    cpx     #52
    bne     @shuffle
    
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
    lda     HAND_PLAYER
    jsr     _blackjack_draw
    sta     HAND_PLAYER
    cmp     #22
    bcs     @stay
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
    dec     IB_READY
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

    lda     HAND_COMPUTER                   ;   A = HAND_COMPUTER
@loop:                                      ;
    clc
    cmp     #17                             ;
    bcs     @end                            ;   while (A < 17) {
    jsr     _blackjack_draw                 ;       A = A + _blackjack_draw;
    bra     @loop                           ;   }
@end:                                       ;
    sta     HAND_COMPUTER                   ;   HAND_COMPUTER = A
    
    dec     DRAWING_DONE

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

    dec     IB_READY
    jmp     ($FFF8)                         ;   Salt la "HOME".

    rts
