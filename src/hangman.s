;
;   File:           hangman.s
;   Description:    Hangman game over UART.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       01.11.2026
;   Version:        1.0.0
;   

;
;   In curs de dezvoltare.
;

.include "inc/memory.inc"
.include "inc/peripherals.inc"
.include "inc/utils.inc"

.feature string_escapes

.rodata
msg_init:
.asciiz "\n\rHANGMAN GAME\n\rWords must be written in uppercase!\n\r\n\rType 'h' to reveal the help menu\n\r"

msg_prompt:
.asciiz "\n\rcharacter > "

msg_lives:
.asciiz "\n\rLives:       "

msg_hidden_word:
.asciiz "\n\rHidden word: "

msg_help:
.asciiz "\n\rHANGMAN HELP MENU\n\rWhen asked for input, type the character you'd like to check for and then press enter.\n\rThe only valid characters are A-Z (uppercase only).\n\rNo special characters allowed.\n\r"

msg_win:
.asciiz "\n\rYou guessed right!\n\r"

msg_error:
.asciiz "\n\rInvalid request.\n\r"

msg_lose:
.asciiz "\n\rYou failed to guess the word.\n\r"

msg_quit:
.asciiz "\n\rQuitting.\n\r"

w0: .asciiz "PROCESSOR"
w1: .asciiz "GALAXY"
w2: .asciiz "PARTICLE"
w3: .asciiz "NATURE"
w4: .asciiz "AIRPLANE"
w5: .asciiz "CRUCEAMATII"
w6: .asciiz "NATURE"
w7: .asciiz "LINUX"

words:
.word   w0
.word   w1
.word   w2
.word   w3
.word   w4
.word   w5
.word   w6
.word   w7

.data
LIVES               =   $00     ;   vieti / incercari ramase.
BUFFER              =   $01     ;   buffer de un caracter.
WORD_PTR            =   $02     ;   [$02, $03] ptr la cuvantul ales.
WORD_HIDDEN_PTR     =   $04     ;   [$04, $05] ptr la cuvantul ascuns.

.code
.global _hangman_init
_hangman_init:
    lda     #$55
    sta     PRNG_SEED

    lda     #<msg_init
    sta     ZP_STRING_BUFFER
    lda     #>msg_init
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write

MAINLOOP:
    lda     #5                              ;
    sta     LIVES                           ;   LIVES = 5

    lda     #8                              ;
    sta     PRNG_SEED                       ;
    sta     PRNG_VAL_MAX                    ;

    jsr     sys_prng                        ;
    asl
    tax
    lda     words, X                        ;
    sta     WORD_PTR                        ;
    lda     words + 1, X                    ;
    sta     WORD_PTR + 1                    ;   char* WORD_PTR = words[X]
    lda     #5
    sta     PRNG_VAL_MAX

    lda     #$00
    sta     WORD_HIDDEN_PTR
    lda     #$7F
    sta     WORD_HIDDEN_PTR + 1

    jsr     _hangman_word_buffer_load       ;   needs more examination

@loop:
    jsr     _hangman_status_print
@loop_buffer:                               ;
    lda     IB_READY                        ;   Asteapta pana cand se poate citi bufferul.
    bne     @loop_buffer                    ;

    jsr     _hangman_buffer_parse
    lda     LIVES                           ;
    beq     @lose                           ;   if (LIVES == 0) goto @lose
    jsr     _hangman_strcmp
    beq     @win
    bra     @loop

@lose:
    lda     #<msg_lose                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_lose                      ;   Afiseaza mesaj lose.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    bra     MAINLOOP

@win:
    lda     #<msg_win                       ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_win                       ;   Afiseaza mesaj win.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    bra     MAINLOOP

_hangman_strcmp:
    ldy     #0

@loop:
    lda     (WORD_PTR), Y
    beq     @end

    cmp     (WORD_HIDDEN_PTR), Y
    bne     @ne

    iny
    bne     @loop
@ne:
    lda     #1
    rts

@end:
    lda     #0
    rts

_hangman_word_buffer_load:
    pha
    phy

    ldy     #0
@loop:
    lda     (WORD_PTR), Y
    beq     @end
    
    lda     #'_'
    sta     (WORD_HIDDEN_PTR), Y
    iny
    bne     @loop

@end:
    lda     #0   
    sta     (WORD_HIDDEN_PTR), Y
    jsr     sys_prng
    tay
    lda     (WORD_PTR), Y
    sta     (WORD_HIDDEN_PTR), Y

    ply
    pla

    rts

_hangman_character_search:
    pha
    phx
    phy
    
    ldx     #0
    ldy     #0
@loop:
    lda     (WORD_PTR), Y
    beq     @lives_check

    cmp     BUFFER
    bne     @skip
    ldx     #1
    sta     (WORD_HIDDEN_PTR), Y

@skip:
    iny
    bne     @loop

@lives_check:
    txa
    bne     @end
    dec     LIVES

@end:
    ply
    plx
    pla

    rts

_hangman_buffer_parse:
    lda     IB_BASE                         ;
    sta     BUFFER                          ;   BUFFER = IB_BASE
    tax

    cmp     #'A'                            ;
    bcc     @continue                       ;   if (A < 'A') check command.
    cmp     #91                             ;
    bcs     @continue                       ;   if (A > 'Z') check command.

    jsr     _hangman_character_search       ;   cauta caracterul in sir.
    bra     @end
@continue:
    txa
    cmp     #'q'
    beq     @quit
    cmp     #'h'
    beq     @help

    bra     @error
@quit:  
    jsr     _hangman_quit
    bra     @end
@help:  
    jsr     _hangman_help
    bra     @end
@error:
    jsr     _hangman_error
@end:
    dec     IB_READY
    rts


_hangman_status_print:
    pha

    lda     #<msg_lives                     ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_lives                     ;   
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    lda     LIVES                           ;   Afiseaza numarul de incercari ramase.
    jsr     sys_num2str                     ;
    lda     #<NUM2STR                       ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>NUM2STR                       ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    lda     #<msg_hidden_word               ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_hidden_word               ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;   Afiseaza cuvantul ascuns.
    lda     WORD_HIDDEN_PTR                 ;
    sta     ZP_STRING_BUFFER                ;
    lda     WORD_HIDDEN_PTR + 1             ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
    lda     #<msg_prompt                    ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_prompt                    ;   Afisare prompt.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    pla

    rts

_hangman_help:
    lda     #<msg_help                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_help                      ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    rts

_hangman_error:
    lda     #<msg_error                     ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_error                     ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    rts

_hangman_quit:
    lda     #<msg_quit                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_quit                      ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    dec     IB_READY
    jmp     ($FFF8)                         ;   salt -> "HOME"

    rts
