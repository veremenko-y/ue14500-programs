; No comments :)

.include "sdk/ue14500-tape.inc"

.segment "MEMLOW"
init: .res 1

.segment "CODE"
    m_programstart
    ld init
    oen QRR
    m_print "Hellorld!"
    sto init
    m_programend