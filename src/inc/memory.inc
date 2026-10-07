.ifndef __MEM_H__
.define __MEM_H__ 1

;   VARIABILE DE SISTEM [$0000, 00FF]

.define z0                      $0000
.define z1                      $0000
.define z2                      $0000
.define z3                      $0000
.define z4                      $0000

.define zp_input_buffer         $00FC   ;   $FC - $FD
.define zp_string_buffer        $00FE   ;   $FE - $FF

;   STIVA HARDWARE      [$0100, $01FF]  ;

;   VARIABILE DE SISTEM [$0200, $0FFF]  ;
.define ib_base                 $0200   ;   inceputul input buffer-ului
.define ib_idx                  $02FF   ;   indicator pentru pozitia din ib_base
.define irq_status              $0300   ;   byte care retine ultimul registru citit dintr-un irq status
.define crc_length              $0300
.define crc                     $0301
.define crc_compare             $0303

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
