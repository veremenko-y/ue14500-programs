.list off

.feature ubiquitous_idents
.feature string_escapes
.setcpu "none"

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


.ifndef REVERSE_BITS
    REVERSE_BITS=0
.endif

.macro _write val
    .if REVERSE_BITS = 1
        ;.byte (((val << 7) & $80) | ((val << 5) & $40) | ((val << 3) & $20) | ((val << 1) & $10)); 
        

        .byte (((val) << 7) & $80) | (((val) << 5) & $40) | (((val) << 3) & $20) |  (((val) << 1) & $10) | (((val) >> 1) & $08) | (((val) >> 3) & $04) | (((val) >> 5) & $02) | (((val) >> 7) & $01)
    .else
        .byte val
    .endif
.endmacro

.macro nop0 addr   ; 0000: NOP0 = No change in registers. RR -> RR. FLG0 high.
    .if .blank(addr)
    _write 0
    .else
    _write <(addr)
    .endif
.endmacro
.macro ld addr    ; 0001: LD   = Load result register. Data -> RR.
    _write (1 << 4) | (<addr)
.endmacro
.macro add addr    ; 0010: ADD  = Addition. D + RR -> RR.
    _write (2 << 4) | (<addr)
.endmacro
.macro sub addr    ; 0011: SUB  = Subtraction. QD + RR -> RR.
    _write (3 << 4) | (<addr)
.endmacro
.macro one addr    ; 0100: ONE  = Force one. 1 -> RR. 0 -> CAR.
    .if .blank(addr)
    _write (4 << 4)
    .else
    _write (4 << 4) | (<addr)
    .endif
.endmacro
.macro nand addr   ; 0101: NAND = Logical NAND. Q(RR * D) -> RR.
    _write (5 << 4) | (<addr)
.endmacro
.macro or addr     ; 0110: OR   = Logical OR. RR + D -> RR.
    _write (6 << 4) | (<addr)
.endmacro
.macro xor addr    ; 0111: XOR  = Exclusive OR. RR != D -> RR.
    _write (7 << 4) | (<addr)
.endmacro
.macro sto addr    ; 1000: STO  = Store. RR -> Data. Write high if OEN.
    _write (8 << 4) | (<addr)
.endmacro
.macro stoc addr   ; 1001: STOC = Store complement. QRR -> Data. Write high if OEN.
    _write (9 << 4) | (<addr)
.endmacro
.macro ien addr   ; 1010: IEN  = Input enable. D -> IEN.
    _write (10 << 4) | (<addr)
.endmacro
.macro oen addr   ; 1011: OEN  = Output enable. D -> OEN.
    _write (11 << 4) | (<addr)
.endmacro
.macro jmp addr   ; 1100: JMP  = Jump. Jump high.
    _write (12 << 4) | (<addr)
.endmacro
.macro rtn addr   ; 1101: RTN  = Return. RTN high. 1 -> Skip.
    .if .blank(addr)
    _write (13 << 4)
    .else
    _write (13 << 4) | (<addr)
    .endif
.endmacro
.macro skz addr   ; 1110: SKZ  = Skip if zero. 1 -> Skip if RR == 0.
    .if .blank(addr)
    _write (14 << 4)
    .else
    _write (14 << 4) | (<addr)
    .endif
.endmacro
.macro nopf addr  ; 1111: NOPF = No change
    .if .blank(addr)
    _write (15 << 4)
    .else
    _write (15 << 4) | (<addr)
    .endif
.endmacro

.define NOP0 nop0
.define LD ld
.define ADD add
.define SUB sub
.define ONE one
.define NAND nand
.define OR or
.define XOR xor
.define STO sto
.define STOC stoc
.define IEN ien
.define OEN oen
.define JMP jmp
.define RTN rtn
.define SKZ skz
.define NOPF nopf

.list on

.define OUTREG $28 ; o61
.define INREG $30 ; o60
.define QRR $38 ; o70
.define RR $39 ; o71
.define HIGH $3a ; o72
.define LOW $3c ; o74
.define SHIFTOUT $3c ; o74
.define BRK $3f ; o77
