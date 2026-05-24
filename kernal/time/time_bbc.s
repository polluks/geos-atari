; GEOS KERNAL for BBC Micro
; Timekeeping - uses jiffyCounter from VIA Timer 1 IRQ

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "bbc.inc"

.import alarmWarnFlag

.global _DoUpdateTime
.global jiffyCounter
.global interrupt_lock
.global __DoUpdateTimeSeconds

.segment "time1"

jiffyCounter:   .byte 0
interrupt_lock: .byte 0

_DoUpdateTime:
    ; Stub time update - for PoC, just check alarm
    lda alarmWarnFlag
    bne :+
    inc alarmWarnFlag
:
    rts

__DoUpdateTimeSeconds:
    ; Stub - updates time of day
    rts
