.ifndef __MEM_H__
.define __MEM_H__ 1

;   VARIABILE ZEROPAGE         [$0000 - 00FF]

.define ZP_INPUT_BUFFER         $00FC   ;   $FC - $FD
.define ZP_STRING_BUFFER        $00FE   ;   $FE - $FF

;   STIVA HARDWARE             [$0100 - $01FF]

;   VARIABILE DE SISTEM        [$0200 - $0FFF]
.define IB_BASE                 $0200   ;   inceputul input buffer-ului
.define IB_IDX                  $02FF   ;   indicator pentru pozitia din ib_base
.define IRQ_STATUS              $0300   ;   byte care retine ultimul registru citit dintr-un irq status
.define CRC                     $0300   ;   crc16 rezultat dupa calcul
.define CRC_LENGTH              $0302   ;   crc16 lungime
.define CRC_COMPARE             $0304   ;   crc16 de comparat

;   STIVA SOFTWARE (REZERVATA) [$1000 - $1FFF]
;   MEMORIE DE PROGRAM         [$2000 - $7FFF]
;   PERIFERICE                 [$8000 - $803F]
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
