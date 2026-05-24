; GEOS Input Driver for BBC Micro
; Keyboard-based mouse simulation (cursor keys + space)
; Fits the input driver API at $FE80

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "jumptab.inc"
.include "bbc.inc"

.segment "hw1b"

.import _DoKeyboardScan

.ifndef bbc
    .assert * = MOUSE_BASE, error, "Input driver not at correct address"
.endif

.global MouseInit
.global SlowMouse
.global UpdateMouse
.global SetMouse

MouseInit:
    jmp _MouseInit
SlowMouse:
    jmp _SlowMouse
UpdateMouse:
    jmp _UpdateMouse
SetMouse:
    jmp _SetMouse

; Mouse state
last_fire:      .byte 0
kb_state:       .byte 0

_MouseInit:
    LoadW mouseXPos, 160
    sta mouseYPos
    lda #160
    sta mouseYPos
    LoadB inputData, $ff
    rts

_SlowMouse:
    LoadB mouseSpeed, NULL
    rts

_UpdateMouse:
    ; Read keyboard for cursor keys
    ; We read the keyboard matrix directly via VIA

    ; This is a simplified version for proof of concept
    ; In a real implementation, we'd read keyboard state
    ; and convert cursor key presses to mouse movement

    ; For now, simulate a static display
    rts

_SetMouse:
    ; Set mouse position from r4 (x), r5L (y)
    MoveW r4, mouseXPos
    MoveB r5L, mouseYPos
    rts
