;
;   File:           monitor.s
;   Description:    A monitor program for analyzing the memory of the system
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       29.10.2026
;   Version:        0.0.1
;   

.include "inc/memory.inc"
.include "inc/peripherals.inc"

;   MONITOR STATUS FLAGS 
;   7   6   5   4   3   2   1   0
;   AL  DL  RG  IA  CWR CRD CHP ERR

;   AL  ->  address loaded
;   DL  ->  data loaded
;   RG  ->  undefined data
;   IFA ->  invalid / forbidden address
;   CWR ->  request for command write
;   CRD ->  request for command read
;   CHP ->  request for command help
;   ERR ->  error

AL      =   $07
DL      =   $06
UD      =   $05
IFA     =   $04
CWR     =   $03
CRD     =   $02
CHP     =   $01
ERR     =   $00

.rodata
_monitor_msg_init:          .asciiz "MEMORY MONITOR\n\r"
_monitor_err_status_flags:  .asciiz "An error occurred while trying to parse your request\n\rMONITOR STATUS FLAG: \n\r"
_monitor_err_command:       .asciiz "Command undefined. Type 'h' to see usage examples\n\r"
_monitor_msg_help:          .asciiz "MONITOR HELP\n\rUSAGE EXAMPLES:\n\r*    r 4000:4FFF     ~   Retrieves the memory contained at [4000, 4FFF]\n\r*    r 4007:         ~   Retrieves the memory contained at [4007, 400F]\n\r*    r FFFA          ~   Retrieves the value at address FFFA\n\r\n\r*    w 3000:30AA 80  ~   Writes 80 in the addresses contained within [3000, 30AA]\n\r*    w 220A: AF      ~   Writes AF in the addresses contained within [220A, 220F]\n\r*    w 5555 7F       ~   Writes 7F at address 5555\n\r\n\rANY ATTEMPT TO TAMPER WITH SPECIAL MEMORY ZONES WILL BE REJECTED!\n\r"
_monitor_status_flags:      .asciiz "AL  DL  RG  IFA CWR CRD CHP ERR\n\r"

.data
MONITOR_STATUS_FLAGS    =   $00
ADDR                    =   $01
ADDR_END                =   $03
VALUE                   =   $05
MASK                    =   $06

.code
.export _monitor_init
_monitor_init:
    lda     #<_monitor_msg_init
    ldy     #>_monitor_msg_init
    jsr     func_uart_string_write
@loop:
    lda     IB_READY
    bne     @loop

    jsr     monitor_buffer_parse
    bbr0    MONITOR_STATUS_FLAGS, @continue         ;   continue if no error was encountered while parsing
    jsr     monitor_error
@continue:
    lda     IB_BASE
    cmp     #'r'
    beq     @read
    cmp     #'w'
    beq     @write
    cmp     #'h'
    beq     @help
    bra     @error
@read:
    jsr     monitor_read
    bra     @end
@write:
    jsr     monitor_write
    bra     @end
@help:
    jsr     monitor_help
    bra     @end
@error:
    lda     #<_monitor_err_command
    lda     #>_monitor_err_command
    jsr     func_uart_string_write
@end:
    dec     IB_READY
    stz     MONITOR_STATUS_FLAGS
    bra     @loop

monitor_buffer_parse:
    pha
    phx
    phy

    ldy     #$00

    stz     MONITOR_STATUS_FLAGS

    lda     IB_BASE
    cmp     #'r'
    beq     @read
    cmp     #'w'
    beq     @write
    cmp     #'h'
    beq     @help
    bra     @error
@read:
    smb3    MONITOR_STATUS_FLAGS
    bra     @address_load
@write:
    smb2    MONITOR_STATUS_FLAGS
    bra     @address_load
@help:
    smb1    MONITOR_STATUS_FLAGS
    bra     @end
@address_load:
    ldx     #$01
    lda     IB_BASE, X
    cmp     #':'
    beq     @address_load_range
    cmp     #' '
    beq     @address_load_end

    ;   process char

    inx
    bra     @address_load
@address_load_range:
    smb5    MONITOR_STATUS_FLAGS
    iny
@address_load_end:
    bbr2    MONITOR_STATUS_FLAGS, @end

    inx
    lda     IB_BASE, X
    cpx     IB_IDX
    beq     @end

@error:
    smb0    MONITOR_STATUS_FLAGS
@end:
    ply
    plx
    pla
    rts

;MONITOR_STATUS_FLAGS    =   $00
;ADDR_START              =   $01
;ADDR_END                =   $03
;VALUE                   =   $05
;MASK                    =   $06

monitor_write:
    pha
    phx

    lda     VALUE

@loop:
    sta     (ADDR)

    inc     ADDR                        ;   if ADDR doesn't overflow,
    bne     @loop                       ;   continue looping

    inc     ADDR + 1                    ;   increment HIGH(ADDR) if LOW(ADDR) overflowed

    ldx     ADDR_END + 1                ;   check HIGH(ADDR_END) == HIGH(ADDR)
    cpx     ADDR + 1                    ;   if not equal,
    bne     @loop                       ;   continue looping

    ldx     ADDR_END                    ;   check LOW(ADDR_END) == LOW(ADDR)
    cpx     ADDR                        ;   if not equal,
    bne     @loop                       ;   continue looping
@end:
    plx
    pla
    rts

;   MONITOR STATUS FLAGS 
;   7   6   5   4   3   2   1   0
;   AL  DL  RG  IA  CWR CRD CHP ERR

monitor_read:
    pha
    phx

@loop:
    lda     (ADDR)

    ;
    ;   send byte (converted) to UART shell
    ;

    inc     ADDR                        ;   if ADDR doesn't overflow,
    bne     @loop                       ;   continue looping

    inc     ADDR + 1                    ;   increment HIGH(ADDR) if LOW(ADDR) overflowed

    ldx     ADDR_END + 1                ;   check HIGH(ADDR_END) == HIGH(ADDR)
    cpx     ADDR + 1                    ;   if not equal,
    bne     @loop                       ;   continue looping

    ldx     ADDR_END                    ;   check LOW(ADDR_END) == LOW(ADDR)
    cpx     ADDR                        ;   if not equal,
    bne     @loop                       ;   continue looping
@end:
    plx
    pla
    rts

monitor_error:
    pha

    lda     #<_monitor_err_status_flags             ;
    lda     #>_monitor_err_status_flags             ;   Reset MONITOR STATUS FLAGS and
    jsr     func_uart_string_write                  ;   print the error.
    lda     #<_monitor_status_flags                 ;
    lda     #>_monitor_status_flags                 ;
    jsr     func_uart_string_write                  ;

    lda     #$80
    sta     MASK
@loop_status_bits:                                  ;
    lda     MONITOR_STATUS_FLAGS                    ;
    and     MASK                                    ;
    adc     #'0'                                    ;   Iterate through all of MONITOR STATUS FLAGS bits
    jsr     func_uart_byte_write                    ;   and print them (MSB first).
    lda     #' '                                    ;   Add blank spaces
    jsr     func_uart_byte_write                    ;
    jsr     func_uart_byte_write                    ;
    lsr     MASK                                    ;
    bcs     @end                                    ;
    bra     @loop_status_bits                       ;
@end:
    lda     #$0D                                    ;
    jsr     func_uart_byte_write                    ;   CR
    lda     #$0A                                    ;
    jsr     func_uart_byte_write                    ;   LF
    pla
    rts

monitor_help:
    pha
    lda     #<_monitor_msg_help                     ;
    lda     #>_monitor_msg_help                     ;   Print the help message
    jsr     func_uart_string_write                  ;
    pla
    rts
