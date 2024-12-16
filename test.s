REVERSE_BITS=1
.include "sdk/ue14500-base.inc"

.segment "MEM"
init:
    .res 1

.segment "CODE"
    ;   ONE                 ; Force 1 into RR
    ;   IEN  RR             ; Load input enable register with 1 from RR
    ;   OEN  RR             ; Load output enable register with 1 from RR
    ;   NAND RR             ; NAND RR with itself to put a 0 in RR

    NOP0 5
    LD 5
    ADD 5
    SUB 5
    ONE 5
    NAND 5
    OR 5
    XOR 5
    STO 5
    STOC 5
    IEN 5
    OEN 5
    JMP 5
    RTN 5
    SKZ 5
    NOPF 5