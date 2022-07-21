; 13 bit Fibonacci number calculations

.include "sdk/ue14500-tape.inc"

.macro __m_bcd13iter out, value, n
.scope
    ; could optimize it with compare to constant
    m_cmpimm 13, value, n
    oen RR ; if carry set
    m_subimm 13, value, n
    oen HIGH
    m_rol 4, out
.endscope
.endmacro

.macro __m_bcd13printNibble nibble
    one
    sto OUTREG+4 ; [0-9] + '0'
    sto OUTREG+5
    stoc OUTREG+6
    stoc OUTREG+7
    sto SHIFTOUT
.endmacro

.macro m_bcd13print tmp, value
.scope
    one
    __m_bcd13iter tmp, value, 8000
    __m_bcd13iter tmp, value, 4000
    __m_bcd13iter tmp, value, 2000
    __m_bcd13iter tmp, value, 1000
    __m_bcd13printNibble out
    __m_bcd13iter tmp, value, 800
    __m_bcd13iter tmp, value, 400
    __m_bcd13iter tmp, value, 200
    __m_bcd13iter tmp, value, 100
    __m_bcd13printNibble out
    __m_bcd13iter tmp, value, 80
    __m_bcd13iter tmp, value, 40
    __m_bcd13iter tmp, value, 20
    __m_bcd13iter tmp, value, 10
    __m_bcd13printNibble out
    m_copy 4, value, out
    __m_bcd13printNibble value
.endscope
.endmacro

.segment "MEMLOW"
    value1: .res 13
    value2: .res 13
    valueTmp: .res 13
    init: .res 1
.segment "MEMOUT"
    out: .res 4 ; 1 BCD digit

.segment "CODE"
    m_programstart

    ld init  ;Load init into RR
    oen QRR
    m_print "Fibonacci13\r"
    one
    sto value1
    sto value2
    sto init

    oen HIGH  ;Turn OEN on again

    ;Start Fibbo
    m_addout 13, value1, value2, value1
    m_ctrr
    skz
    m_brk
    m_copy 13, value1, valueTmp
    m_bcd13print out, valueTmp
    m_print "\r"
    
    m_addout 13, value1, value2, value2
    m_ctrr
    skz
    m_brk
    m_copy 13, value2, valueTmp
    m_bcd13print out, valueTmp
    m_print "\r"

    m_programend