.feature ubiquitous_idents
.feature string_escapes
.setcpu "none"

; Real-ish tape data
;   16 bit data bus, first 4 bits are ignored but stored in
;   executable in current implementation
;   8 bit address bus
;   xxxxIIII DDDDDDDD
; IO xxNNNNNN (first two bits are masked):
;   LD/STO  0x30-0x37   IO
;       STO 0x30     - Trigger to read 1 bit from input - yes/no
;       LD 0x30      - Read result
;       STO 0x31     - Write 7 byte ASCII into terminal
;       STO 0x32     - Break (any value)
;       0x33-0x37 - Reserved
;   LD/STO  0x38        QRR
;   LD/STO  0x39        RR
;   LD      0x3A-0x3B   High
;   LD      0x3C-0x3F   Low

; 0000 0: NOP0 = No change in registers. RR -> RR. FLG0 high.
; 0001 1: LD   = Load result register. Data -> RR.
; 0010 2: ADD  = Addition. D + RR -> RR.
; 0011 3: SUB  = Subtraction. QD + RR -> RR.
; 0100 4: ONE  = Force one. 1 -> RR. 0 -> CAR.
; 0101 5: NAND = Logical NAND. Q(RR * D) -> RR.
; 0110 6: OR   = Logical OR. RR + D -> RR.
; 0111 7: XOR  = Exclusive OR. RR != D -> RR.
; 1000 8: STO  = Store. RR -> Data. Write high if OEN.
; 1001 9: STOC = Store complement. QRR -> Data. Write high if OEN.
; 1010 A: IEN  = Input enable. D -> IEN.
; 1011 B: OEN  = Output enable. D -> OEN.
; 1100 C: JMP  = Jump. Jump high.
; 1101 D: RTN  = Return. RTN high. 1 -> Skip.
; 1110 E: SKZ  = Skip if zero. 1 -> Skip if RR == 0.
; 1111 F: NOPF = No change in registers. RR -> RR. FLGF high.

.macro nop0 addr   ; 0000: NOP0 = No change in registers. RR -> RR. FLG0 high.
    .byte 0
    .if .blank(addr)
    .byte 0
    .else
    .byte <addr
    .endif
.endmacro
.macro ld addr    ; 0001: LD   = Load result register. Data -> RR.
    .byte 1
    .byte <addr
.endmacro
.macro add addr    ; 0010: ADD  = Addition. D + RR -> RR.
    .byte 2
    .byte <addr
.endmacro
.macro sub addr    ; 0011: SUB  = Subtraction. QD + RR -> RR.
    .byte 3
    .byte <addr
.endmacro
.macro one    ; 0100: ONE  = Force one. 1 -> RR. 0 -> CAR.
    .byte 4
    .byte 0
.endmacro
.macro nand addr   ; 0101: NAND = Logical NAND. Q(RR * D) -> RR.
    .byte 5
    .byte <addr
.endmacro
.macro or addr     ; 0110: OR   = Logical OR. RR + D -> RR.
    .byte 6
    .byte <addr
.endmacro
.macro xor addr    ; 0111: XOR  = Exclusive OR. RR != D -> RR.
    .byte 7
    .byte <addr
.endmacro
.macro sto addr    ; 1000: STO  = Store. RR -> Data. Write high if OEN.
    .byte 8
    .byte <addr
.endmacro
.macro stoc addr   ; 1001: STOC = Store complement. QRR -> Data. Write high if OEN.
    .byte 9
    .byte <addr
.endmacro
.macro ien addr   ; 1010: IEN  = Input enable. D -> IEN.
    .byte 10
    .byte <addr
.endmacro
.macro oen addr   ; 1011: OEN  = Output enable. D -> OEN.
    .byte 11
    .byte <addr
.endmacro
.macro jmp addr   ; 1100: JMP  = Jump. Jump high.
    .byte 12
    .byte <addr
.endmacro
.macro rtn   ; 1101: RTN  = Return. RTN high. 1 -> Skip.
    .byte 13
    .byte 0
.endmacro
.macro skz   ; 1110: SKZ  = Skip if zero. 1 -> Skip if RR == 0.
    .byte 14
    .byte 0
.endmacro
.macro nopf addr  ; 1111: NOPF = No change
    .byte 15
    .byte <addr
.endmacro

.define OUTREG $28 ; o61
.define INREG $30 ; o60
.define QRR $38 ; o70
.define RR $39 ; o71
.define HIGH $3a ; o72
.define LOW $3c ; o74
.define SHIFTOUT $3c ; o74
.define BRK $3f ; o77

.macro m_printbyte bits, addr
    .repeat 8,I
        .if (I < bits)
            ld addr+I
            sto OUTREG+I
        .else
            one
            stoc OUTREG+I
        .endif
    .endrepeat
    sto SHIFTOUT
.endmacro


.macro m_printbyteimm value
    .repeat 8,I
    .if (value & (1 << I)) <> 0
    sto OUTREG+I ; 1
    .else
    stoc OUTREG+I ; 0
    .endif
    .endrepeat
    sto SHIFTOUT
.endmacro

.macro m_print str
    one
    .repeat .strlen(str), I
    __tmp .set .strat(str, I)
    m_printbyteimm __tmp
    .endrepeat
.endmacro

.macro m_brk
    sto BRK
.endmacro

; Assumes RR register is 0 at start
.macro m_programstart
    ien HIGH
    ien	HIGH
    oen HIGH
    oen QRR
    .repeat $30,I
    sto I
    .endrepeat
    .repeat $bf,I
    sto $40+I
    .endrepeat
.endmacro
    
; Must reset RR to 1 to avoid clearing RAM
.macro m_programend
    one
.endmacro

.macro m_save_oen tmpAddr
    one
    sto tmpAddr
.endmacro

.macro m_restore_oen tmpAddr
    oen tmpAddr
    one
    stoc tmpAddr ; zero tmpoen if was 1
.endmacro

.macro m_clc ; clear carry
    one
.endmacro

.macro m_sec ; set carry
    ld HIGH
    add HIGH
.endmacro

.macro m_ctrr ; transfer carry to RR
    ld LOW
    add LOW
.endmacro

.macro m_load bits, dstAddr, value
    one
    .repeat bits,I
        .if (value & (1 << I)) <> 0
        sto dstAddr+I; 1
        .else
        stoc dstAddr+I; 0
        .endif
    .endrepeat
.endmacro

.macro m_fill bits, dstAddr, value
    one
    .repeat bits,I
        .if value = 0
        stoc dstAddr+I; 0
        .elseif value = 1
        sto dstAddr+I; 1
        .else
        .out "Value must be 0 or 1"
        .endif
    .endrepeat
.endmacro

.macro m_cmp bits, targetAddr, compAddr
    ; C: A>=B
    ; !C: A<B
    m_sec
    .repeat bits,I
        ld targetAddr+I
        sub compAddr+I
    .endrepeat
    m_ctrr
    .if .referenced(CFlag)
    sto CFlag
    .endif
.endmacro

.macro m_cmpimmz bits, targetAddr, compValue
    ; C: A>=B
    ; !C: A<B
    ; .out .sprintf("Cmp %d", compValue)
    ; .if .not .referenced(ZFlag)
    ;     .out "Memory for 1 bit with label ZFlag must be defined to use this macro."
    ; .endif
    one
    stoc ZFlag
    m_sec
    .repeat bits,I
        ld targetAddr+I
        .if (compValue & (1 << I)) <> 0
        ; .out "1"
        sub HIGH
        .else
        ; .out "0"
        sub LOW
        .endif
        or ZFlag ; z is 1 if result is 0
        sto ZFlag
    .endrepeat
    .if .referenced(CFlag)
    m_ctrr
    sto CFlag
    ld ZFlag ; z is 1 if carry is 1
    .endif
    stoc ZFlag ; invert z to get 1 if result is 0
    ld ZFlag
.endmacro

.macro m_cmpimm bits, targetAddr, compValue
    ; C: A>=B
    ; !C: A<B
    m_sec
    .repeat bits,I
        ld targetAddr+I
        .if (compValue & (1 << I)) <> 0
        sub HIGH
        .else
        sub LOW
        .endif
    .endrepeat
    m_ctrr
    .if .referenced(CFlag)
    sto CFlag
    .endif
.endmacro

.macro m_subout bits, op1Addr, op2Addr, outAddr
    m_sec
    .repeat bits,I
    ld op1Addr+I
    sub op2Addr+I
    sto outAddr+I
    .endrepeat
.endmacro

.macro m_sub bits, op1Addr, op2Addr
    m_subout bits, op1Addr, op2Addr, op1Addr
.endmacro

.macro m_subimm bits, op1Addr, op2Value
    m_sec
    .repeat bits,I
    ld op1Addr+I
    .if (op2Value & (1 << I)) <> 0
    sub HIGH
    .else
    sub LOW
    .endif
    sto op1Addr+I
    .endrepeat
.endmacro

.macro m_asl bits, value
    m_clc
    .repeat bits,I
    ld value+I
    add value+I
    sto value+I
    .endrepeat
.endmacro

.macro m_lsr bits, value
    m_clc
    .repeat bits,I
    ld value+(bits-I-1)
    add value+(bits-I-1)
    sto value+(bits-I-1)
    .endrepeat
.endmacro

; rotate left with carry
.macro m_rol bits, value
    .repeat bits,I
    ld value+I
    add value+I
    sto value+I
    .endrepeat
.endmacro

; rotate ror with carry
.macro m_ror bits, value
    .repeat bits,I
    ld value+(bits-I-1)
    add value+(bits-I-1)
    sto value+(bits-I-1)
    .endrepeat
.endmacro

.macro m_copy bits, srcAddr, dstAddr
    .repeat bits,I
    ld srcAddr+I
    sto dstAddr+I
    .endrepeat
.endmacro

.macro m_addout bits, op1Addr, op2Addr, outAddr
    m_clc
    .repeat bits,I
    ld op1Addr+I
    add op2Addr+I
    sto outAddr+I
    .endrepeat
.endmacro

.macro m_add bits, op1Addr, op2Addr
    m_addout bits, op1Addr, op2Addr, op1Addr
.endmacro

.macro m_adcimm bits, op1Addr, op2Value
    .repeat bits,I
    ld op1Addr+I
    .if (op2Value & (1 << I)) <> 0
    add HIGH
    .else
    add LOW
    .endif
    sto op1Addr+I
    .endrepeat
.endmacro

.macro m_xor bits, op1Addr, op2Value
    .repeat bits,I
    ld op1Addr+I
    .if (op2Value & (1 << I)) <> 0
    xor HIGH
    .else
    xor LOW
    .endif
    sto op1Addr+I
    .endrepeat
.endmacro

.macro m_addimm bits, op1Addr, op2Value
    m_clc
    .repeat bits,I
    ld op1Addr+I
    .if (op2Value & (1 << I)) <> 0
    add HIGH
    .else
    add LOW
    .endif
    sto op1Addr+I
    .endrepeat
.endmacro

.macro __m_sqr16_iter valueAddr, resultAddr    
.scope
    tempsq = scratchpad
    currentbitsq = scratchpad + 8

    m_asl 8, resultAddr ; low * 2    
    m_rol 8, resultAddr+8 ; high * 2 + carry    
    m_asl 8, currentbitsq ; shift number byte    
    m_ctrr ; read carry    
    oen RR ; if carry = 1    
    m_add 8, resultAddr, tempsq    
    m_adcimm 8, resultAddr+8, 0 ; add carry to result
    oen tmpoen
.endscope
.endmacro

.macro m_sqr16 valueAddr, resultAddr
.scope
    tempsq = scratchpad
    currentbitsq = scratchpad + 8

    one
    sto tmpoen

    m_load 8, resultAddr, 0
    m_copy 8, valueAddr, currentbitsq ; save low
    ld valueAddr+15 ; check if negative
    oen RR    
    m_xor 8, currentbitsq, $FF ; negate low byte
    m_addimm 8, currentbitsq, 1 ; +1
    oen tmpoen    
    m_copy 8, currentbitsq, tempsq ; save low ABS

    ; do this 8 times
    .repeat 8
    __m_sqr16_iter valueAddr, resultAddr
    .endrepeat
    
    oen tmpoen
    one
    stoc tmpoen ; zero tmpoen if was 1
.endscope
.endmacro

.macro m_mul16 op1Addr, op2Addr, resultAddr
.scope
    tempOp1 = scratchpad
    tempOp2 = tempOp1 + 16
    sign = tempOp2 + 16

    one ; store current O
    sto tmpoen

    m_copy 16, op2Addr, tempOp2
    ld tempOp2+15 ; calculate sign
    sto sign
    oen sign ; if negative, invert the number
    m_xor 16, tempOp2, $ffff
    m_addimm 16, tempOp2, 1
    oen tmpoen

    m_load 16, tempOp1, 0
    m_copy 16, op1Addr, resultAddr
    m_lsr 16, resultAddr
    m_ctrr
    sto CFlag
    ; do this 8 times
    .repeat 16
        ; using oen RR or oen CFlag is bad
        ; because they can be 0 or 1 depending on what ran first
        ; but it's alright here, because when this code runs it doesn't
        ; garble anything, then tmpoen restores the O state
        oen CFlag ; if C = 0
        m_sec
        m_add 16, tempOp1, tempOp2
        
        oen tmpoen ; always
        m_clc
        m_ror 16, tempOp1
        m_ror 16, resultAddr
        m_ctrr
        sto CFlag
    .endrepeat

    oen sign ; negate result if negative
    m_xor 16, resultAddr, $ffff
    m_addimm 16, resultAddr, 1
    oen tmpoen
    one
    stoc tmpoen ; zero tmpoen if was 1
.endscope
.endmacro
