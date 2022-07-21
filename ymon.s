; Simple and useless monitor 

.include "sdk/ue14500-tape.inc"

.macro m_parseAddr destAddr
.scope
    m_save_oen tmp
    
    m_copy 7, INREG, tmp7
    m_cmpimm 7, tmp7, 'A'
    oen HIGH
    nand tmp 
    oen QRR ; if carry and enabled
    m_sec
    m_subimm 7, tmp7, $7
    oen tmp
    m_sec
    m_subimm 7, tmp7, $30
    m_copy 4, tmp7, destAddr

    m_restore_oen tmp
.endscope
.endmacro

.macro m_printOne srcAddr, str, value
    m_save_oen tmp
    m_cmpimmz 4, srcAddr, value
    oen ZFlag
    m_print str
    m_restore_oen tmp
.endmacro

.macro m_printHex srcAddr
    ; alghorithm http://forum.6502.org/viewtopic.php?f=2&t=6564&p=82994#p82994
    m_save_oen tmp

    m_load 3, tmp7+4, 0             ; clear high 3 bits
    m_copy 4, srcAddr, tmp7

    m_cmpimm 4, srcAddr, $A
    oen HIGH                        ; if value >= 0xa or carry set
    nand tmp
    oen QRR
    m_sec
    m_adcimm 7, tmp7, $66
    
    oen tmp
    m_xor 7, tmp7, $30
    m_printbyte 7, tmp7

    m_restore_oen tmp
.endmacro

.segment "MEMLOW"
    addr: .res 8
    init: .res 1
    index: .res 1
    parseCommand: .res 1
    parseAddress: .res 1
    renderData: .res 1
    finishRender: .res 1
    continiousModeEnter: .res 1
    continiousModeContinue: .res 1
    command: .res 1
    tmp: .res 1
    tmp7: .res 1
    ZFlag: .res 1

.segment "MEMHIGH"

.segment "CODE"
    m_programstart

    ld init
    oen QRR
    stoc parseCommand
    stoc init
    
    oen HIGH ; reset tmp
    one
    stoc tmp
    oen LOW

    ; --- Parse Command ---
    oen parseCommand
    m_print "/"
    sto INREG
    
    m_cmpimmz 7, INREG, 'R'
    skz                             ; if IN == R
    sto tmp
    oen tmp
    stoc tmp
    stoc command
    stoc parseCommand               ; now read address
    stoc index                      ; reset index
    sto parseAddress

    oen parseCommand                ; else w
    m_cmpimmz 7, INREG, 'W'
    skz                             ; if IN == R
    sto tmp
    oen tmp
    stoc tmp
    sto command
    stoc parseCommand               ; now read address
    stoc index                      ; reset index
    sto parseAddress

    oen parseCommand                ; else error
    m_print "\rE\r"

    oen HIGH                        ; reset tmp after use
    one
    stoc tmp
    oen LOW

    ; --- Parse Address High ---

    oen HIGH
    ld index
    xor HIGH
    nand parseAddress               ; if index 0
    oen QRR

    sto INREG ; read first
    
    ; --- Check for continious mode ---
    ; if enter, switch to continious mode
    ; in which we use previously stored
    ; address
    m_save_oen tmp
    m_cmpimmz 7, INREG, $0d         ; \n
    sto continiousModeEnter
    oen continiousModeEnter
    m_addimm 8, addr, 1
    stoc tmp                        ; mess up saved oen
    stoc parseAddress               ; disable parse address
    sto renderData                  ; enable render
    m_restore_oen tmp

    m_parseAddr addr+4
    one
    sto index

    ; --- Parse Address Low---

    oen HIGH
    ld index
    nand parseAddress               ; if index 1
    oen QRR

    sto INREG
    m_parseAddr addr
    one
    stoc parseAddress
    sto renderData

    oen renderData
    m_print "\r"
    m_printHex addr+4
    m_printHex addr
    m_print ": "

    oen HIGH ; reset tmp
    one
    stoc tmp
    oen LOW

    ; --- Render ---

    .repeat 256,I
        oen HIGH
        m_cmpimmz 8, addr, I
        nand renderData
        oen QRR
        one
        sto tmp

        ; now branch for command
        oen HIGH
        ld command
        nand renderData
        xor HIGH
        nand tmp                    ; if command is W
        oen QRR
            ; do write
            sto INREG
            ; "proper" way m_cmpimmz 7, INREG, '1'
            ; cheat and only compare low bit
            ld INREG
            skz
            sto I
            ld QRR
            skz
            stoc I

            one
            sto finishRender
            stoc renderData
        one 
        stoc tmp ; reset tmp
        oen LOW

        oen HIGH
        ld command
        xor HIGH
        nand renderData
        xor HIGH
        nand tmp                    ; if command is W
        oen QRR
            ; do read
            ld I
            sto OUTREG+0
            one
            stoc OUTREG+1
            stoc OUTREG+2
            stoc OUTREG+3
            sto OUTREG+4
            sto OUTREG+5
            stoc OUTREG+6
            sto SHIFTOUT
            sto finishRender
            stoc renderData
        one 
        stoc tmp ; reset tmp
        oen LOW
    .endrepeat

    oen continiousModeEnter
    one
    stoc continiousModeEnter
    sto continiousModeContinue

    oen continiousModeContinue
    m_addimm 8, addr, 1
    one
    stoc parseCommand               ; override, do not continue parsing
    stoc finishRender               ; finish render will reset continious mode
    sto renderData                  ; but render data instead
    sto INREG
    m_cmpimmz 7, INREG, $0d         ; \n
    xor HIGH
    skz                             ; if not \n 
    sto finishRender

    ; this is needed to minimize the code
    ; duplicated 256 times. not much
    ; but somethint
    oen finishRender
    m_print "\r"
    sto parseCommand
    stoc continiousModeContinue

    m_programend