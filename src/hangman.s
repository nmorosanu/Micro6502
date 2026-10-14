.include "inc/memory.inc"
.include "inc/peripherals.inc"
.include "inc/utils.inc"

.rodata
_msg_hangman_init:
.asciiz "Starting HANGMAN"

_msg_hangman_wordis:
.asciiz "WORD IS: "

_msg_hangman_lives:
.asciiz "Lives: "

_msg_hangman_win:
.asciiz "You win!"

_msg_hangman_lose:
.asciiz "You lost. The word was "

ARRAY_WORDS:
.word w0,w1,w2,w3,w4,w5,w6,w7

w0: .asciiz "PROCESSOR"
w1: .asciiz "PARTICLE"
w2: .asciiz "FOREST"
w3: .asciiz "HIKING"
w4: .asciiz "SCIENCE"
w5: .asciiz "WDC65C02"
w6: .asciiz "GALAXY"
w7: .asciiz "ARCHITECTURE"

WORD_POINTER            =   $0010
WORD_HIDDEN_POINTER     =   $0012
WORD_LENGTH             =   $2004
TMP                     =   $200C
TMP_2                   =   $200F
LIVES                   =   $201A

word_hidden:
    .asciiz "_________________________________"

word_hidden_print:
    pha
    phy

    ldy     #$00
@loop:                                      ;
    lda     (WORD_HIDDEN_POINTER), Y        ;
    beq     @end                            ;   loop as long as we reach the end of word_hidden (NULL)
    cpy     WORD_LENGTH                     ;   or until we reached the end of the chosen word's length
    beq     @end                            ;
    iny                                     ;
    bra     @loop                           ;

@end:
    ply
    pla

    rts

.export _hangman_init
_hangman_init:
    stz     WORD_LENGTH

    lda     #<word_hidden                   ;
    sta     WORD_HIDDEN_POINTER             ;
    lda     #>word_hidden                   ;
    sta     WORD_HIDDEN_POINTER + 1         ;

    lda     #$05                            ;
    sta     LIVES                           ;   start with 5 lives

    jsr     _rng                            ;   generate prng for using as index in wordlist

    tax                                     ;
    lda     ARRAY_WORDS, X                  ;
    sta     WORD_POINTER                    ;
    inx                                     ;   retrieve pointer to the corresponding word
    lda     ARRAY_WORDS, X                  ;
    sta     WORD_POINTER + 1                ;
    dex                                     ;

    ldy     #$00                            ;
@length_calculate:                          ;
    lda     (WORD_POINTER), Y               ;   calculate the length
    beq     @length_calculate_end           ;   of the chosen word
    bra     @length_calculate               ;
@length_calculate_end:
    iny
    sty     WORD_LENGTH

@loop:
    lda     IB_READY
    bne     @loop

    cmp     #$7E                            ;
    beq     @exit                           ;   exit, if char is '~'
    
    cmp     #$0A                            ;
    bne     @loop                           ;   check char, if we recieved CR
    jsr     _check_byte                     ;

    lda     #$FF                            ;
    sta     IB_READY                        ;   reset input buffer ready signal
    
    bra     @loop
@exit:
    jmp     $FFFC

_check_byte:
    pha
    phx
    phy

    ldx     IB_IDX                          ;
    dex                                     ;   get byte before CR

    lda     IB_BASE, X                      ;
    sta     TMP                             ;   char to check is in TMP

    ldy     #$00
@loop_word_hidden:
    lda     (WORD_POINTER), Y               ;
    beq     @end                            ;   if the current byte matches any byte from the chosen word,
    cmp     TMP                             ;   show the character thats been chosen.
    beq     @char_found                     ;

    iny

    bra     @loop_word_hidden
@char_found:                                ;
    sta     (WORD_HIDDEN_POINTER), Y        ;
    iny                                     ;   unmask the character from the hidden word
    bra     @loop_word_hidden               ;

@end:
    ply
    plx
    pla

    rts
