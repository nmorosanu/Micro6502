.ifndef __MEM_H__
.define __MEM_H__ 1

;   VARIABILE DE SISTEM [$0000, 00FF]

.define zp_input_buffer         $0000   ;   $00 - $01
.define zp_string_buffer        $0002   ;   $02 - $03
.define zp_tmp                  $00A0   ;   $A0 - $EF
.define zp_uart_header          $00F0   ;   $F0 - $FD
.define zp_adr_prg              $00FE   ;   $FE - $FF

;   VARIABILE DE SISTEM [$0200, $0FFF]
.define ib_idx          $0200
.define irq_status      $0201
.define tmp             $0EFF
.define ib_base         $0F00

;   STIVA SOFTWARE      [$1000, $1FFF]
;   MEMORIE DE PROGRAM  [$2000, $7FFF]
;   PERIFERICE          [$8000, $803F]
.define ACIA_DATA       $8000
.define ACIA_STATUS     $8001
.define ACIA_COMMAND    $8002
.define ACIA_CONTROL    $8003
.define VIA_PORTB       $8010
.define VIA_PORTA       $8011
.define VIA_DDRB        $8012
.define VIA_DDRA        $8013
.define VIA_T1CL        $8014
.define VIA_T1CH        $8015
.define VIA_T1LL        $8016
.define VIA_T1LH        $8017
.define VIA_T2CL        $8018
.define VIA_T2CH        $8019
.define VIA_SR          $801A
.define VIA_ACR         $801B
.define VIA_PCR         $801C
.define VIA_IFR         $801D
.define VIA_IER         $801E
.define VIA_PORTA_NH    $801F

.endif
