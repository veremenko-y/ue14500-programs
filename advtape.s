; Simple input test. 

.include "sdk/ue14500-tape.inc"

.segment "MEMLOW"
temp: .res 1

.segment "CODE"
    m_programstart

    oen HIGH
    m_print "?\r"
    sto INREG
    ld INREG
    sto temp 
    oen QRR
    m_print "Chose n\r"
    oen temp
    m_print "Chose y\r"
    
    m_programend