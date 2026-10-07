.include "inc/memory.inc"
.include "inc/peripherals.inc"

.rodata
_msg_hangman_init:   .asciiz "  HANGMAN  -  Press any key to continue..."

_msg_hangman_lives:  .asciiz "  Lives: "

_msg_hangman_win:    .asciiz "  You win!"

_msg_hangman_lose:   .asciiz "  You lose. The word was "

words:  .asciiz "PROCESSOR"
        .asciiz "PARTICLE"
        .asciiz "FOREST"
        .asciiz "HIKING"
        .asciiz "SCIENCE"
        .asciiz "WDC65C02"
        .asciiz "GALAXY"
        .asciiz "ARCHITECTURE"


SEED            = $00F0
WORD_POINTER    = $00F1
STRING_POINTER  = $00F3
LIVES           = $00F4

.code
.export hangman_init
hangman_init:
    lda     #<_msg_hangman_init
    sta     ZP_STRING_BUFFER
    lda     #>_msg_hangman_init
    sta     ZP_STRING_BUFFER
    jsr     _uart_write_string

    lda     $0000
    and     #$07
    sta     SEED
    lda     #<words
    sta     WORD_POINTER
    lda     #>words
    sta     WORD_POINTER + 1

draw_frame:
    lda     #<_msg_hangman_lives
    sta     ZP_STRING_BUFFER
    lda     #>_msg_hangman_lives
    sta     ZP_STRING_BUFFER + 1
    jsr     _uart_write_string
    lda     LIVES
    jsr     _uart_write_byte

@ib_parse:  
    lda     IB_BASE
    ldx     IB_IDX

    bra     hangman_init
