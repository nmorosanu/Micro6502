;
;   File:           hangman.s
;   Description:    Hangman game over UART.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       31.10.2026
;   Version:        0.0.1
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"
.include "inc/utils.inc"

.rodata
msg_init:
.asciiz "\n\rHANGMAN GAME\n\rWords must be written in uppercase!\n\r\n\rType 'h' to reveal the help menu\n\r"

msg_prompt:
.asciiz "character > "

msg_status:
.asciiz "character > "

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

.data
WORD_BUFFER_BASE    =   $7FBF   ;   inceputul copiei pentru cuvantul selectat.
QUIT                =   $00     ;   indica dorinta de a inchide programul.
LIVES               =   $01     ;   vieti / incercari ramase.
GUESSED             =   $02     ;   numarul de ghicite.
BUFFER              =   $03     ;   buffer de un caracter.
WORD_IDX            =   $04     ;   indicele cuvantului din lista de cuvinte.
WORD_PTR            =   $05     ;   ptr la cuvantul ales.
WORD_LENGTH         =   $06     ;   ptr la cuvantul ales.
WORD_HIDDEN_PTR     =   $07     ;   ptr la cuvantul ascuns.

.code
.global _hangman_init
_hangman_init:
    lda     #<msg_init
    sta     ZP_STRING_BUFFER
    lda     #>msg_init
    sta     ZP_STRING_BUFFER + 1
    jsr     sys_uart_string_write
    stz     QUIT
@loop:
    jsr     _hangman_loop
    lda     QUIT                            ;
    beq     @loop                           ;
    jmp     ($FFF8)                         ;   salt la "HOME", daca QUIT != 0

_hangman_loop:
    lda     #3                              ;
    sta     LIVES                           ;   LIVES = 3

    lda     #4                              ;
    sta     PRNG_VAL_MAX                    ;
    jsr     sys_prng                        ;
    sta     WORD_IDX                        ;   WORD_IDX = random(0, 3)

    jsr     _hangman_word_length
    jsr     _hangman_word_buffer_load
@loop:
    lda     #<msg_status                    ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_status                    ;   Afisare mesaj cu status.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    lda     #<WORD_HIDDEN_PTR               ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>WORD_HIDDEN_PTR               ;   Afisare cuvant ascuns.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    lda     #<msg_prompt                    ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_prompt                    ;   Afisare prompt.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

@loop_buffer:                               ;
    lda     IB_READY                        ;   Asteapta pana cand se poate citi bufferul.
    beq     @loop_buffer                    ;

    lda     IB_BASE                         ;
    sta     BUFFER                          ;   BUFFER = IB_BASE

    jsr     _hangman_buffer_parse
    lda     LIVES
    beq     @lose
    jsr     _hangman_strcmp
    beq     @win
    bra     @loop
@lose:
    lda     #<msg_lose                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_lose                      ;   Afiseaza mesaj lose.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;
@win:
    lda     #<msg_win                       ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_win                       ;   Afiseaza mesaj win.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    rts

_hangman_strcmp:

@loop:
    lda     (WORD_PTR), Y                   ;
    beq     @end                            ;   while (A != '\0') {

    cmp     (WORD_HIDDEN_PTR), Y            ;       if (WORD_PTR[Y] != WORD_HIDDEN_PTR[Y])
    beq     @loop                           ;           return 1;
                                            ;       ++Y;
    lda     #1                              ;   }

    rts                                     ;

@end:                                       ;   return 0;
    lda     #0                              ;

    rts

_hangman_word_buffer_load:
    rts

_hangman_character_search:
    pha
    phx
    phy

    ldx     #0                              ;   X = 0
    ldy     #0                              ;   Y = 0

@loop:                                      ;
    lda     (WORD_PTR), Y                   ;   while (WORD_PTR[Y] != 0) {
    beq     @loop_end                       ;       if (BUFFER == WORD_PTR[Y]) {
    cmp     BUFFER                          ;           X = 1;
    bne     @not_found                      ;           WORD_HIDDEN_PTR[Y] = BUFFER;
                                            ;       }
    ldx     #1                              ;       Y = Y + 1;
    lda     BUFFER                          ;   }
    sta     (WORD_HIDDEN_PTR), Y            ;
                                            ;
@not_found:                                 ;
    iny                                     ;
    bra     @loop                           ;

@loop_end:                                  ;
    txa                                     ;   if (X == 0)
    bne     @end                            ;       LIVES = LIVES - 1;
    dec     LIVES                           ;   

@end:
    ply
    plx
    pla
    rts

_hangman_buffer_parse:
    lda     BUFFER
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
    rts

_hangman_word_length:
    pha
    phy

    ldy     #$00                            ;   Y = 0
@loop:                                      ;
    lda     (WORD_PTR), Y                   ;
    beq     @end                            ;   A = 0 -> salt la @end
    iny                                     ;   Y = Y + 1
    bra     @loop                           ;   continua
@end:
    sty     WORD_LENGTH                     ;   WORD_LENGTH = Y
    ply
    pla
    rts

_hangman_help:
    lda     #<msg_help                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_help                      ;   Afiseaza meniul help.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    rts

_hangman_error:
    lda     #<msg_error                     ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_error                     ;   Afiseaza meniul help.
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    rts

_hangman_quit:
    lda     #<msg_quit                      ;
    sta     ZP_STRING_BUFFER                ;
    lda     #>msg_quit                      ;
    sta     ZP_STRING_BUFFER + 1            ;
    jsr     sys_uart_string_write           ;

    inc     QUIT                            ;   QUIT = 1 -> salt la "HOME"
    rts
