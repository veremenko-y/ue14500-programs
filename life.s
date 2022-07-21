; Game of life

; Reference: https://www.cypherpunk.at/2015/10/calculating-fractals-with-integer-operations/
.include "sdk/ue14500-tape.inc"

.define FIELD_W 9
.define FIELD_H 9
FIELD_SIZE = FIELD_W * FIELD_H
CNT_BITS = 5

.macro m_countNbrs xx, yy
.scope
    .if xx >= 0 && yy >= 0 && xx < FIELD_W && yy < FIELD_H
        ; addr = fieldOld + (yy * 9) + xx
        nop0 xx
        nop0 yy
        m_clc
        ld (fieldOld + FIELD_W * (yy) + (xx))
        add HIGH ; results in carry
        m_adcimm 4, count, 0
    .endif
.endscope
.endmacro

.segment "MEMLOW"
    count: .res 4
    init: .res 1
    ZFlag: .res 1
    CFlag: .res 1
    dead: .res 1
    tmp: .res 1

.segment "MEMHIGH"
    field: .res FIELD_SIZE
    fieldOld: .res FIELD_SIZE
   
; SOH $01 - go to 0,0

.segment "CODE"
    ien HIGH
    ien	HIGH
    oen HIGH
    oen QRR
    .repeat $30,I
    sto I
    .endrepeat
    ; do not clear high memory, leave random

    oen HIGH
    m_print "\x01"
    m_copy FIELD_SIZE, field, fieldOld
    m_fill FIELD_SIZE, field, 0 
    .repeat FIELD_H, YY
    .repeat FIELD_W, XX
    .scope
    m_load 4, count, 0
    m_countNbrs XX-1, YY+1
    m_countNbrs XX-1, YY
    m_countNbrs XX-1, YY-1

    m_countNbrs XX, YY+1
    m_countNbrs XX, YY-1

    m_countNbrs XX+1, YY+1
    m_countNbrs XX+1, YY
    m_countNbrs XX+1, YY-1

    addrOld = fieldOld + YY * FIELD_W + XX
    addrNew = field    + YY * FIELD_W + XX
    ld addrOld
    stoc dead
    oen addrOld ; if alive
        m_print "X"
        sto addrNew ; store alive 
        m_cmpimmz 4, count, 2
        stoc tmp
        m_cmpimmz 4, count, 3
        xor HIGH
        nand tmp
        xor HIGH
        ; RR = 1 if do not equal 2 or 3
        skz
        stoc addrNew ; stode dead
    oen dead ; if dead
        m_print " "
        m_cmpimmz 4, count, 3
        skz ; if count == 3
        sto addrNew
    oen HIGH
    .endscope
    .endrepeat
    m_print "\r"
    .endrepeat

    m_programend