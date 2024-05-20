; Yaroslav Veremenko 2024-05-20
; Simple 2 bit addition example
;
; Assume little-endian bit packing.
; E.g. 4 bit number 1 = 0b1011 is going to be stored in 
; memory as lowest bit first.
; 00:1b
; 01:1b
; 02:0b
; 03:1b

.include "sdk/ue14500-tape.inc"

.segment "MEMLOW"
term1 = $00
term2 = $02
sum   = $04

.segment "CODE"
    ien HIGH        ; Init. Enable memory in/out
    ien	HIGH
    oen HIGH

    oen QRR         ; Assuming RR is 0 at reset
                    ; This code will only execute once
    
    one             ; Clear carry
    ; Assuming little endian bit packing
    ld term1+0
    add term2+0
    sto sum+0

    ld term1+1
    add term2+1
    sto sum+1

    one             ; Reset RR