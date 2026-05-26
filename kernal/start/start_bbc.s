; GEOS KERNAL for BBC Micro
; Boot/start sequence from sideways ROM
;
; ROM header at $8000
;   $8000: ROM type ($80)
;   $8001-$8007: title ("GEOS   ")
;   $8008-$8009: service entry offset
;   $800A-$800B: (unused)

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "bbc.inc"

.import InitGEOEnv
.import _DoFirstInitIO
.import FirstInit
.import ClrScr
.import SetPattern
.import i_Rectangle
.import i_InvertRectangle
.import i_FrameRectangle
.import FrameRectangle
.import VerticalLine
.import i_ImprintRectangle
.import DBIcPicOK
.import DBIcPicYES
.import DBIcPicNO
.import i_BitmapUp
.import UseSystemFont
.import i_PutString
.import PutChar
.import MainLoop
.import DoMenu
.import GotoFirstMenu
.import DoIcons
.import GraphicsString
.import DrawLine
.import DrawPoint
.import GetNextChar
.import GetString
.import MouseInit
.import dateCopy
.import EnterDeskTop

.import _IRQHandler
.import _DoKeyboardScan
.import initVIA

.global _ResetHandle
.global rom_service

; ROM Header
; Standard BBC sideways ROM format:
;   $8000: language entry (JMP or $00 if none)
;   $8003: service entry (JMP or $00 if none)
;   $8006: ROM type byte ($40 = service only, $C0 = language+service)
;   $8007: version (BCD)
;   $8008: null-terminated title
.segment "rom_header"
    .byte $00, $00, $00         ; no language entry
    jmp rom_service             ; service entry (3 bytes: $4C, lo, hi)
    .byte $82                   ; ROM type: service entry (bit7=1) no language
    .byte $90                   ; bit7=1: copyright offset $10 → $8010; also version 1.0
    .byte "GEOS", $00           ; null-terminated title
    .byte $00, $00, $00         ; padding to $8010
    .byte $00, $28, $43, $29   ; "(C)" copyright string for MOS boot scan

; ===========================================================
; Service entry - called by MOS
;   A = service call number
;   For $04 (unrecognised *command): Y = offset in ($F2) buffer
; ===========================================================
.segment "start"
rom_service:
    stx $12                 ; save our ROM slot number
    cmp #$09                ; *HELP service call
    beq help_command
    cmp #$04                ; unrecognised *command
    beq check_command
    rts                     ; unhandled, return A unchanged (non-zero = continue scan)

; -----------------------------------------------------------------------
; *HELP: print help text, return A != 0 (don't claim, let other ROMs print)
; -----------------------------------------------------------------------
help_command:
    jsr print_help_text
    lda #1                  ; A != 0: continue scanning to next ROM
    rts

; -----------------------------------------------------------------------
; Unrecognised *command: Y = offset to command in ($F2) string buffer
; -----------------------------------------------------------------------
check_command:
    tya
    clc
    adc $F2
    sta r0L
    lda #0
    adc $F3
    sta r0H
    ldy #0
    jsr skip_spaces
    ldy #0
:   lda cmd_geos,y
    beq match_geos
    cmp (r0L),y
    bne not_match
    iny
    bne :-
match_geos:
    jmp _ResetHandle
not_match:
    lda #1                  ; A != 0: continue scanning to next ROM
    rts

cmd_geos:
    .byte "GEOS", 0

help_text:
    .byte "GEOS KERNEL for BBC", 13, 10, 0

print_help_text:
    ldx #0
:   lda help_text,x
    beq :+
    jsr OSWRCH
    inx
    bne :-
:   rts

; ===========================================================
; Reset Handler
; ===========================================================
_ResetHandle:
    sei
    cld
    ldx #$FF
    txs

    ; Initialize hardware (mode set via OS, may clobber vectors)
    jsr init_hardware

    ; Install our IRQ handler into OS vector
    lda #<_IRQHandler
    sta $0202
    lda #>_IRQHandler
    sta $0203

    ; Clear BSS area ($2E00-$2FFF)
    lda #0
    ldx #0
:   sta $2E00,x
    sta $2F00,x
    inx
    bne :-

    ; Init GEOS kernel
    jsr InitGEOEnv
    jsr MouseInit

    ; Draw checkerboard test pattern (verify hardware display)
    jsr draw_checkerboard

    ; Delay ~2 seconds so user can see the checkerboard
    lda #12
    sta r4L
delay_1:
    lda #0
    sta r3L
delay_2:
    lda #0
    sta r2L
delay_3:
    dec r2L
    bne delay_3
    dec r3L
    bne delay_2
    dec r4L
    bne delay_1

    ; Draw to screen
    jsr draw_desktop

    ; Start 100Hz timer and enter GEOS main loop
    jsr initVIA
    cli
    jmp EnterDeskTop

skip_spaces:
:   lda (r0L),y
    cmp #$20
    bne :+
    iny
    bne :-
:   tya
    clc
    adc r0L
    sta r0L
    bcc :+
    inc r0H
:   rts

; ===========================================================
; Hardware Initialization
; ===========================================================
init_hardware:
    ; Configure System VIA
    lda #%00000000
    sta SYSVIA_DDRA         ; Port A input (keyboard rows)
    lda #%01111111
    sta SYSVIA_DDRB         ; Port B 0-6 output (keyboard columns)

    ; Disable all interrupts from VIA
    lda #%10000000          ; Bit 7 = 1 means disable
    sta SYSVIA_IER
    lda #%01111111
    sta SYSVIA_IER

    ; Use OS to set mode 4 (320x256, 2 colours, 1bpp linear)
    lda #22
    jsr OSWRCH
    lda #4
    jsr OSWRCH

    ; Override R6 = 25 (200 scanlines = 25 rows × 8, not OS default 32)
    lda #CRTC_R6
    sta CRTC_ADDR
    lda #25
    sta CRTC_DATA

    ; Override start address: MA=$0938 → physical $3000+$0938=$3938
    ; SCREEN_BASE=$3900, pixel data at $3938 (= SCREEN_BASE + 56)
    lda #CRTC_R12
    sta CRTC_ADDR
    lda #$09                ; high 6 bits of MA = $09
    sta CRTC_DATA
    lda #CRTC_R13
    sta CRTC_ADDR
    lda #$38                ; low 8 bits of MA = $38
    sta CRTC_DATA

    ; Clear screen to black ($3900-$5FFF = 9KB)
    lda #>$3900
    sta r0H
    lda #<$3900
    sta r0L
    ldy #0
    tya
:   sta (r0),y
    iny
    bne :-
    inc r0H
    lda r0H
    cmp #$60
    bne :-

    rts

; ===========================================================
; Draw desktop-like display to linear framebuffer
; ===========================================================
draw_desktop:
    ; Clear screen
    jsr ClrScr

    ; Draw desktop background
    lda #2
    jsr SetPattern

    ; Top menu bar (8 pixels high, full width)
    jsr i_Rectangle
    .byte 0, 7
    .word 0, 319

    ; Draw icon area (right side)
    lda #4
    jsr SetPattern
    jsr i_Rectangle
    .byte 8, 199
    .word 280, 319

    ; Main area
    lda #0
    jsr SetPattern
    jsr i_Rectangle
    .byte 8, 199
    .word 0, 279

    ; Draw menu bar text
    jsr UseSystemFont
    LoadW windowTop, 0
    LoadW leftMargin, 4
    LoadW windowBottom, 199
    LoadW rightMargin, 315

    ; Menu items
    jsr i_PutString
    .word 1
    .byte 1
    .byte "GEOS  DESKTOP  FILE  DISK"
    .byte 0

    ; Draw file icons in main area
    jsr i_BitmapUp
    .word DBIcPicYES
    .byte 30
    .byte 40
    .byte 6, 16

    jsr i_BitmapUp
    .word DBIcPicNO
    .byte 60
    .byte 40
    .byte 6, 16

    jsr i_BitmapUp
    .word DBIcPicOK
    .byte 90
    .byte 40
    .byte 6, 16

    ; Label the icons
    jsr i_PutString
    .word 91
    .byte 40
    .byte "HELLO"
    .byte 0

    jsr i_PutString
    .word 121
    .byte 40
    .byte "WORLD"
    .byte 0

    jsr i_PutString
    .word 151
    .byte 40
    .byte "DESKTOP"
    .byte 0

    ; Draw a bordered dialog box
    lda #3
    jsr SetPattern
    jsr i_FrameRectangle
    .byte 60, 140
    .word 40, 240
    .byte $FF

    ; Dialog box background
    lda #1
    jsr SetPattern
    jsr i_Rectangle
    .byte 61, 139
    .word 41, 239

    ; Dialog text
    lda #0
    jsr SetPattern
    jsr i_Rectangle
    .byte 61, 139
    .word 41, 239

    jsr UseSystemFont
    LoadW leftMargin, 56
    LoadW rightMargin, 230

    jsr i_PutString
    .word 80
    .byte 75
    .byte "GEOS BBC Micro"
    .byte 0

    jsr i_PutString
    .word 96
    .byte 90
    .byte "Proof of Concept"
    .byte 0

    jsr i_PutString
    .word 108
    .byte 105
    .byte "Kernel in ROM"
    .byte 0

    ; OK button at bottom of dialog
    lda #3
    jsr SetPattern
    jsr i_FrameRectangle
    .byte 120, 135
    .word 100, 180
    .byte $FF

    lda #1
    jsr SetPattern
    jsr i_Rectangle
    .byte 121, 134
    .word 101, 179

    jsr UseSystemFont
    LoadW leftMargin, 114
    LoadW rightMargin, 170

    jsr i_PutString
    .word 126
    .byte 126
    .byte "OK"
    .byte 0

    rts

; ===========================================================
; Draw checkerboard test pattern to verify hardware display
; 8x8 pixel squares, alternating black/white
; Writes directly to screen memory at $3038 (CRTC start addr)
; ===========================================================
draw_checkerboard:
    lda #0
    sta r2L                 ; Y = 0

yc_cb:
    ; Compute Y * 40 into r0
    lda r2L
    sta r1L
    lda #0
    sta r1H

    ; r1 = Y * 8
    asl r1L
    rol r1H
    asl r1L
    rol r1H
    asl r1L
    rol r1H

    ; r0 = Y * 8
    lda r1L
    sta r0L
    lda r1H
    sta r0H

    ; r1 = Y * 32
    asl r1L
    rol r1H
    asl r1L
    rol r1H

    ; r0 = Y * 8 + Y * 32 = Y * 40
    clc
    lda r0L
    adc r1L
    sta r0L
    lda r0H
    adc r1H
    sta r0H

    ; Add $3938 = SCREEN_BASE + 56
    clc
    lda r0L
    adc #$38
    sta r0L
    lda r0H
    adc #$39
    sta r0H

    ; Determine base pattern for this row of 8-scanline squares
    lda r2L
    lsr
    lsr
    lsr                     ; Y / 8
    and #1                  ; row parity (0 or 1)
    sta r4L

    lda #0
    sta r3L                 ; byte offset = 0

xc_cb:
    lda r3L
    and #1
    eor r4L                 ; byte parity XOR row parity
    bne black_cb
    lda #$FF
    bne write_cb
black_cb:
    lda #$00
write_cb:
    ldy #0
    sta (r0L),y

    inc r3L
    lda r3L
    cmp #40
    beq next_y_cb

    ; Advance dest pointer by 1
    inc r0L
    bne xc_cb
    inc r0H
    jmp xc_cb

next_y_cb:
    inc r2L
    lda r2L
    cmp #200
    bne yc_cb

    rts

; ===========================================================
; Helper for string comparison
; ===========================================================
push_word:
    pha
    txa
    pha
    rts
