; GEOS KERNAL for BBC Micro
; IRQ handler - uses System VIA Timer 1 for 100Hz tick

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "bbc.inc"

.import _DoKeyboardScan
.import CallRoutine
.import jiffyCounter
.import KbdQueFlag
.import ledDivider

; Vars
.global _IRQHandler
.global _NMIHandler
.global _BRKHandler
.global initVIA

.segment "irq"

; Initialize VIA Timer 1 for 100Hz interrupts
initVIA:
    ; Set up VIA Timer 1 in free-run mode
    ; ACR bit 7 = 0 (PB7 disabled), bit 6 = 1 (free-run mode)
    ; We want Timer 1 in free-run mode with continuous interrupts
    lda #%01000000
    sta SYSVIA_ACR

    ; Load Timer 1 latch with count for 100Hz
    lda #<39999
    sta SYSVIA_T1LL
    lda #>39999
    sta SYSVIA_T1LH

    ; Write to T1CL/T1CH to start timer and clear interrupt
    sta SYSVIA_T1CH

    ; Enable Timer 1 interrupt
    lda #%11000000          ; Set bit 7 = 1 (enable), bit 6 = 1 (Timer 1)
    sta SYSVIA_IER

    rts

; IRQ handler
_IRQHandler:
    cld
    pha
    txa
    pha
    tya
    pha

    ; Check VIA interrupt flags
    lda SYSVIA_IFR
    and #VIA_IFR_T1        ; Timer 1 interrupt?
    beq irq_end

    ; Acknowledge Timer 1 interrupt by reading T1CL
    lda SYSVIA_T1CL

    ; Slow blink Caps Lock LED at ~1Hz (divider counts to 100 at 100Hz)
    inc ledDivider
    lda ledDivider
    cmp #100
    bne :+
    lda #0
    sta ledDivider
:

    ; Increment jiffy counter for timekeeping
    inc jiffyCounter

    ; Call keyboard scan
    jsr _DoKeyboardScan

    ; Restore Caps Lock LED state after keyboard scan (which overwrites PB0)
    lda ledDivider
    cmp #50
    bcs :+
    lda SYSVIA_ORB
    and #$FE              ; clear bit 0 = LED on (active low)
    sta SYSVIA_ORB
    jmp :++
:   lda SYSVIA_ORB
    ora #$01              ; set bit 0 = LED off
    sta SYSVIA_ORB
:

    ; Check keyboard queue flag
    ldy KbdQueFlag
    beq :+
    iny
    beq :+
    dec KbdQueFlag

    ; Call VBlank-level vectors
:   lda intTopVector
    ldx intTopVector+1
    jsr CallRoutine

irq_end:
    pla
    tay
    pla
    tax
    pla
    rti

; NMI handler (unused in this port)
_NMIHandler:
    rti

; BRK/panic handler
_BRKHandler:
    rti
