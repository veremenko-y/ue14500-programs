; 8 bit fibonacci number calculations

.include "sdk/ue14500-tape.inc"

.macro m_bcd8iter value, n
    m_cmpimm 8, value, n
    oen RR ; if carry set
    m_subimm 8, value, n
    oen HIGH
    .if n >= 100
    m_rol 4, out1
    .else
    m_rol 4, out2
    .endif
.endmacro

.macro m_bcd8 value
    one
    stoc out1+0
    stoc out1+1

    m_bcd8iter value, 200
    m_bcd8iter value, 100
    m_bcd8iter value, 80
    m_bcd8iter value, 40
    m_bcd8iter value, 20
    m_bcd8iter value, 10
    m_copy 4, value, out3
.endmacro

.macro m_bcd8printNibble nibble
    m_copy 4, nibble, OUTREG
    one
    sto OUTREG+4
    sto OUTREG+5
    stoc OUTREG+6
    stoc OUTREG+7
    sto SHIFTOUT
.endmacro

; prints value distructively
.macro m_bcd8print value
    m_bcd8 value
    m_bcd8printNibble out1
    m_bcd8printNibble out2
    m_bcd8printNibble out3
.endmacro

.segment "MEMLOW"
    out1: .res 4 ; first BCD digit
    out2: .res 4 ; second BCD digit
    out3: .res 4 ; third BCD digit
    init: .res 1
.segment "MEMHIGH"
    value1: .res 8
    value2: .res 8
    value3: .res 8
    valueTmp: .res 8

.segment "CODE"
    m_programstart

    ld init  ;Load init into RR
    oen QRR

    m_print "Fibonacci\r"
    one
    sto value1
    sto value2
    one
    sto init

    oen HIGH  ;Turn OEN on again

    ;Start Fibbo
    m_addout 8, value1, value2, value3
    m_ctrr
    skz
    m_brk
    m_copy 8, value3, value1

    m_bcd8print value3
    m_print "\r"
    
    m_addout 8, value1, value2, value3
    m_ctrr
    skz
    m_brk
    m_copy 8, value3, value2

    m_bcd8print value3
    m_print "\r"

    m_programend