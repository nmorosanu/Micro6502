;
;   File:           main.s
;   Description:    Auxiliary file for simulating and debugging purposes.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       01.11.2026
;   Version:        0.0.1
;   

;
;   Fisierul poate sa nu fie inclus la deployment.
;   Fisierul are uz doar pentru simulari cu sim65.
;

.include    "./inc/vectors.inc"
.code
.export     _main
_main:      jmp     RESET
