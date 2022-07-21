; 80 characters wide Mandelbrot

; Reference: https://www.cypherpunk.at/2015/10/calculating-fractals-with-integer-operations/
.include "sdk/ue14500-tape.inc"

.macro __m_bcd16iter value, n
.scope
    out1 = scratchpad+4*0
    out2 = scratchpad+4*1
    out3 = scratchpad+4*2
    out4 = scratchpad+4*3
    out5 = scratchpad+4*4
    ; could optimize it with compare to constant
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
.endscope
.endmacro

.macro m_bcd16 value
.scope
    out1 = scratchpad+4*0
    out2 = scratchpad+4*1
    out3 = scratchpad+4*2
    out4 = scratchpad+4*3
    out5 = scratchpad+4*4
    one
    stoc out1+0 ; zero low bit  
    __m_bcd16iter value, 40000
    __m_bcd16iter value, 20000
    __m_bcd16iter value, 10000
    __m_bcd16iter value, 8000
    __m_bcd16iter value, 4000
    __m_bcd16iter value, 2000
    __m_bcd16iter value, 1000
    __m_bcd16iter value, 800
    __m_bcd16iter value, 400
    __m_bcd16iter value, 200
    __m_bcd16iter value, 100
    __m_bcd16iter value, 80
    __m_bcd16iter value, 40
    __m_bcd16iter value, 20
    __m_bcd16iter value, 10
    m_copy 4, value, out5
.endscope
.endmacro

.macro __m_bcd16printNibble nibble
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
.scope
    out1 = scratchpad+4*0
    out2 = scratchpad+4*1
    out3 = scratchpad+4*2
    out4 = scratchpad+4*3
    out5 = scratchpad+4*4
    m_bcd16 value
    __m_bcd16printNibble out1
    __m_bcd16printNibble out2
    __m_bcd16printNibble out3
    __m_bcd16printNibble out4
    __m_bcd16printNibble out5
.endscope
.endmacro

DRAW_TERMINAL_SYMBOLS = 1
NES_TERMINAL = 0

NORM_BITS = 5
NORM_FACT = 32
NORM_FACT4 = $0080  ;  4 * NORM_FACT
MAX_ITER = 12
VAL_BITS = 16

.if NES_TERMINAL = 1
    SCREEN_WIDTH = 28
    SCREEN_HEIGHT = 19  ; use 8 for half the fractal
    ; I know these numbers are not "correct"
    REAL_MIN = $ffc0    ;  -2.0 * NORM_FACT
    REAL_MAX = $0016    ;  0.7 * NORM_FACT
    IMAG_MIN = $0000    ;  0 * NORM_FACT (draw only top half)
    IMAG_MAX = $0026    ;  1.2 * NORM_FACT
    DELTA_REAL = $0003  ; (REAL_MAX - REAL_MIN) / SCREEN_WIDTH
    DELTA_IMAG = $0004  ; (IMAG_MAX - IMAG_MIN) / SCREEN_HEIGHT ! calculated for heigh 8
    CNT_BITS = 5
.else
    SCREEN_WIDTH = 80
    SCREEN_HEIGHT = 24
    REAL_MIN = $ffc0 ;  -2.0 * NORM_FACT
    REAL_MAX = $0016 ;  0.7 * NORM_FACT
    IMAG_MIN = $ffda ;  -.2 * NORM_FACT (draw only top half)
    IMAG_MAX = $0026 ;  1.2 * NORM_FACT
    DELTA_REAL = $0001; (REAL_MAX - REAL_MIN) / SCREEN_WIDTH
    DELTA_IMAG = $0003; (IMAG_MAX - IMAG_MIN) / SCREEN_HEIGHT
    CNT_BITS = 7
.endif


.macro __m_drawTilelIf iter, value, byte
    m_cmpimmz CNT_BITS, iter, value
    oen RR
    m_printbyte byte
    oen tmpoen
.endmacro

.macro __m_drawCharlIf iter, value, chr
    m_cmpimmz CNT_BITS, iter, value
    oen RR
    m_print chr
    oen tmpoen
.endmacro

.macro m_drawPixel iter
    one
    sto tmpoen

    .if DRAW_TERMINAL_SYMBOLS = 1
        __m_drawCharlIf iter, 0, " "
        __m_drawCharlIf iter, 1, " "
        __m_drawCharlIf iter, 2, "."
        __m_drawCharlIf iter, 3, "."
        __m_drawCharlIf iter, 4, "-"
        __m_drawCharlIf iter, 5, "="
        __m_drawCharlIf iter, 6, "="
        __m_drawCharlIf iter, 7, "+"
        __m_drawCharlIf iter, 8, "*"
        __m_drawCharlIf iter, 9, "#"
        __m_drawCharlIf iter, 10, "%"
        __m_drawCharlIf iter, 11, "@"
    .else
        __m_drawTilelIf iter, 0, $00
        __m_drawTilelIf iter, 1, $0c
        __m_drawTilelIf iter, 2, $0d
        __m_drawTilelIf iter, 3, $0e
        __m_drawTilelIf iter, 4, $0f
        __m_drawTilelIf iter, 5, $10
        __m_drawTilelIf iter, 6, $11
        __m_drawTilelIf iter, 7, $12
        __m_drawTilelIf iter, 8, $13
        __m_drawTilelIf iter, 9, $14
        __m_drawTilelIf iter, 10, $15
        __m_drawTilelIf iter, 11, $01
    .endif
    oen tmpoen
    one
    stoc tmpoen ; zero tmpoen if was 1
.endmacro

.segment "MEMLOW"
    real0: .res VAL_BITS
    imag0: .res VAL_BITS
    init: .res 1
    ZFlag: .res 1
    CFlag: .res 1
    outerloop: .res 1
    innerloop: .res 1
    iterateloop: .res 1
    tmpoen: .res 1

.segment "MEMHIGH"
    real: .res VAL_BITS
    imag: .res VAL_BITS
    realq: .res VAL_BITS
    imagq: .res VAL_BITS
    iter: .res 8 ; placed 8 bits apart for easy debugging
    xx: .res 8
    yy: .res 8
    tmp: .res VAL_BITS
    scratchpad: .res 33

.segment "CODE"
    m_programstart

    ld init
    oen QRR
    m_print "Fractal\r"
    sto init
    sto outerloop
    m_load VAL_BITS, imag0, IMAG_MAX
    m_load CNT_BITS, yy, 0

    ; outerloop start
    oen outerloop
    m_load VAL_BITS, real0, REAL_MIN
    m_load CNT_BITS, xx, 0
    
    ; innerloop start
    one
    stoc outerloop ; disable outerloop
    sto innerloop ; enable innerloop

    oen innerloop
    m_load CNT_BITS, iter, 0
    m_copy VAL_BITS, real0, real
    m_copy VAL_BITS, imag0, imag
    
    ; iterloop start
    one
    stoc innerloop ; disable innerroop
    sto iterateloop ; enable iterateloop

    oen iterateloop

    m_sqr16 real, realq
    skz
    .repeat NORM_BITS
    m_lsr VAL_BITS, realq
    .endrepeat

    m_sqr16 imag, imagq
    skz
    .repeat NORM_BITS
    m_lsr VAL_BITS, imagq
    .endrepeat

    m_addout VAL_BITS, realq, imagq, scratchpad
    m_cmpimm VAL_BITS, scratchpad, NORM_FACT4
    skz
    stoc iterateloop
    oen iterateloop ; break

    ; calculate next imag
    m_mul16 imag, real, tmp
    .repeat (NORM_BITS-1)
    one ; clear carry, RR <- 0
    ld tmp+15
    skz ; if tmp is negative
    add HIGH ; force carry in
    m_ror VAL_BITS, tmp
    .endrepeat

    m_addout VAL_BITS, tmp, imag0, imag

    ; calculate next real
    m_subout VAL_BITS, realq, imagq, real
    m_add VAL_BITS, real, real0

    ; iterloop next
    m_addimm CNT_BITS, iter, 1
    m_cmpimmz CNT_BITS, iter, (MAX_ITER-1)
    skz
    stoc iterateloop ; end if iter == MAX_ITER

    ; innerloop next
    oen HIGH
    ld iterateloop
    oen QRR
    stoc innerloop ; enable inner loop
    m_drawPixel iter
    m_addimm VAL_BITS, real0, DELTA_REAL
    m_addimm CNT_BITS, xx, 1
    m_cmpimmz CNT_BITS, xx, SCREEN_WIDTH
    skz
    stoc innerloop ; end if xx == SCREEN_WIDTH

    ; outerloop next
    oen HIGH
    ld innerloop
    or iterateloop
    oen QRR ; if end inner loop
    stoc outerloop ; enable outer loop
    m_subimm VAL_BITS, imag0, DELTA_IMAG
    m_addimm CNT_BITS, yy, 1
    m_cmpimmz CNT_BITS, yy, SCREEN_HEIGHT
    skz
    m_brk ; done

    m_programend