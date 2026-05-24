; GEOS KERNAL for BBC Micro
; Hardware initialization

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "bbc.inc"

.import KbdQueHead
.import KbdQueTail
.import KbdQueFlag

.global _DoFirstInitIO

.segment "hw1b"

_DoFirstInitIO:
    php
    sei

    ; Configure System VIA for keyboard
    lda #%00000000
    sta SYSVIA_DDRA         ; Port A input (keyboard rows)
    lda #%01111111
    sta SYSVIA_DDRB         ; Port B 0-6 output (columns), bit 7 input

    ; Disable all VIA interrupts
    lda #%10000000
    sta SYSVIA_IER
    lda #%01111111
    sta SYSVIA_IER

    ; Clear keyboard queue
    lda #0
    sta KbdQueHead
    sta KbdQueTail
    lda #$FF
    sta KbdQueFlag

    plp
    rts
