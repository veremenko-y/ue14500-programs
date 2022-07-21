; 16 bit Fibonacci number calculations (with extended memory)

.include "sdk/ue14500-tape.inc"

.macro m_bcd16iter value, n
    m_cmpimm 16, value, n
    oen RR ; if carry set
    m_subimm 16, value, n
    oen HIGH
    .if n >= 10000
    m_rol 4, out1
    .elseif n >= 1000
    m_rol 4, out2
    .elseif n >= 100
    m_rol 4, out3
    .else
    m_rol 4, out4
    .endif
.endmacro

.macro m_bcd16 value
    one
    stoc out1+0
    m_bcd16iter value, 40000
    m_bcd16iter value, 20000
    m_bcd16iter value, 10000
    m_bcd16iter value, 8000
    m_bcd16iter value, 4000
    m_bcd16iter value, 2000
    m_bcd16iter value, 1000
    m_bcd16iter value, 800
    m_bcd16iter value, 400
    m_bcd16iter value, 200
    m_bcd16iter value, 100
    m_bcd16iter value, 80
    m_bcd16iter value, 40
    m_bcd16iter value, 20
    m_bcd16iter value, 10
    m_copy 4, value, out5
.endmacro

.macro m_bcd16printNibble nibble
    m_copy 4, nibble, OUTREG
    one
    sto OUTREG+4 ; [0-9] + '0'
    sto OUTREG+5
    stoc OUTREG+6
    stoc OUTREG+7
    sto SHIFTOUT
.endmacro

; prints value distructively
.macro m_bcd16print value
    m_bcd16 value
    m_bcd16printNibble out1
    m_bcd16printNibble out2
    m_bcd16printNibble out3
    m_bcd16printNibble out4
    m_bcd16printNibble out5
.endmacro

.segment "MEMLOW"
    out1: .res 4 ; 1 BCD digit
    out2: .res 4 ; 2 BCD digit
    out3: .res 4 ; 3 BCD digit
    out4: .res 4 ; 4 BCD digit
    out5: .res 4 ; 5 BCD digit
    init: .res 1
.segment "MEMHIGH"
    value1: .res 16
    value2: .res 16
    value3: .res 16
    valueTmp: .res 16

.segment "CODE"
    m_programstart

    ld init  ;Load init into RR
    oen QRR

    m_print "Fibonacci16\r"
    one
    sto value1
    sto value2
    one
    sto init

    oen HIGH  ;Turn OEN on again

    ;Start Fibbo
    m_addout 16, value1, value2, value3
    m_ctrr
    skz
    m_brk
    m_copy 16, value3, value1
    m_bcd16print value3
    m_print "\r"
    
    m_addout 16, value1, value2, value3
    m_ctrr
    skz
    m_brk
    m_copy 16, value3, value2
    m_bcd16print value3
    m_print "\r"

    m_programend