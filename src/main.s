;
;   File:           main.s
;   Description:    Auxiliary file for simulating and debugging purposes.
;   Author:         Morosanu Nicolas
;   Created:        29.10.2026
;   Modified:       29.10.2026
;   Version:        0.0.1
;   

.include    "./inc/vectors.inc"
.code
.export     _main
_main:      jmp     RESET
