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
    .byte $10                   ; version 1.0 / copyright offset to $8010
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

    ; Install our IRQ handler into OS vector
    lda #<_IRQHandler
    sta $0202
    lda #>_IRQHandler
    sta $0203

    ; Initialize hardware
    jsr init_hardware

    ; Clear BSS area ($5800-$59FF)
    lda #0
    ldx #0
:   sta $5800,x
    sta $5900,x
    inx
    bne :-

    ; Init GEOS kernel
    jsr InitGEOEnv
    jsr MouseInit

    ; Draw to linear framebuffer
    jsr draw_desktop

    ; Convert framebuffer to BBC mode 1 screen format
    jsr fb_to_screen

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

    ; Set CRTC for mode 1 (320x200, 4 colors)
    ; R0=127, R1=80, R2=98, R3=40, R4=38, R5=0, R6=25
    ; R7=32, R8=33, R9=7

    ldx #0
crtc_loop:
    lda crtc_regs,x
    sta CRTC_ADDR
    inx
    lda crtc_regs,x
    sta CRTC_DATA
    inx
    cpx #24                 ; 12 registers * 2 bytes
    bne crtc_loop

    ; Set Video ULA for mode 1 (80 col, graphics)
    lda #%00000011
    sta VIDULA_CTL

    ; Clear screen to black ($3000-$79FF)
    lda #>$3000
    sta r0H
    lda #<$3000
    sta r0L
    ldy #0
    tya
:   sta (r0),y
    iny
    bne :-
    inc r0H
    lda r0H
    cmp #$7A
    bne :-

    rts

crtc_regs:
    .byte CRTC_R0, 127
    .byte CRTC_R1, 80
    .byte CRTC_R2, 98
    .byte CRTC_R3, 40
    .byte CRTC_R4, 38
    .byte CRTC_R5, 0
    .byte CRTC_R6, 25
    .byte CRTC_R7, 32
    .byte CRTC_R8, 33      ; interlace (1MHz, 20kHz)
    .byte CRTC_R9, 7       ; 8 scanlines per char row
    .byte CRTC_R12, 0      ; Start address high
    .byte CRTC_R13, 0      ; Start address low

; ===========================================================
; Draw desktop-like display to framebuffer at $7000
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
; Convert framebuffer ($7000) to BBC mode 1 screen ($3000)
;
; GEOS: 40 bytes/scanline, 200 scanlines, 1bpp, linear
; BBC mode 1: interleaved, 2bpp
;
; Uses zero-page registers:
;   r0L/r0H = source pointer
;   r1L/r1H = dest / temp pointer
;   r2L = Y counter (0-199)
;   r3L = byte counter (0-39)
;   r4L = char_row (Y/8), temp
;   r5L = char_scan (Y%8)
;   r6L/r6H = dest address computation
; ===========================================================
fb_to_screen:
    lda #0
    sta r2L                 ; Y = 0

yloop:
    lda r2L
    lsr
    lsr
    lsr                     ; A = Y/8
    sta r4L                 ; char_row

    lda r2L
    and #7
    sta r5L                 ; char_scan

    lda #0
    sta r3L                 ; byte counter = 0

byteloop:
    jsr convert_pixels

    inc r3L
    lda r3L
    cmp #40
    bne byteloop

    inc r2L
    lda r2L
    cmp #200
    bne yloop

    rts

; Convert one GEOS byte to 2 BBC bytes and write to screen
convert_pixels:
    ; Source = SCREEN_BASE + 56 + Y * 40 + byte_n
    ; Compute Y * 40 using 16-bit arithmetic: Y*40 = Y*32 + Y*8 = (Y<<5) + (Y<<3)
    lda r2L                 ; Y (0-199)
    sta r1L
    lda #0
    sta r1H                 ; r1 = Y (16-bit)

    ; r1 = Y * 8
    asl r1L
    rol r1H
    asl r1L
    rol r1H
    asl r1L
    rol r1H                 ; r1 = Y * 8

    ; r0 = r1 = Y * 8
    lda r1L
    sta r0L
    lda r1H
    sta r0H

    ; r1 = Y * 32
    asl r1L
    rol r1H
    asl r1L
    rol r1H                 ; r1 = Y * 32

    ; r0 = r0 + r1 = Y * 8 + Y * 32 = Y * 40
    clc
    lda r0L
    adc r1L
    sta r0L
    lda r0H
    adc r1H
    sta r0H

    ; Add byte_n
    clc
    lda r0L
    adc r3L
    sta r0L
    lda r0H
    adc #0
    sta r0H

    ; Add SCREEN_BASE + 56
    clc
    lda r0L
    adc #<(SCREEN_BASE + 56)
    sta r0L
    lda r0H
    adc #>(SCREEN_BASE + 56)
    sta r0H

    ldy #0
    lda (r0L),y             ; Read GEOS byte
    sta r7L                 ; geos_byte

    ; GEOS framebuffer: bit 7 = leftmost pixel, bit 0 = rightmost pixel
    ; BBC Mode 1: addr = pixels 0-3 (left), addr+1 = pixels 4-7 (right)
    ;   Each pixel = 2 bits: %00 = black, %11 = white (monochrome)

    ; Pass 1: create BBC byte 0 (pixels 0-3, from GEOS bits 7-4)
    lda #0
    asl r7L
    bcc :+
    ora #%11000000
:   asl r7L
    bcc :+
    ora #%00110000
:   asl r7L
    bcc :+
    ora #%00001100
:   asl r7L
    bcc :+
    ora #%00000011
:   sta r7H                 ; Save BBC byte 0 (pixels 0-3)

    ; Pass 2: create BBC byte 1 (pixels 4-7, from GEOS bits 3-0)
    lda #0
    asl r7L
    bcc :+
    ora #%11000000
:   asl r7L
    bcc :+
    ora #%00110000
:   asl r7L
    bcc :+
    ora #%00001100
:   asl r7L
    bcc :+
    ora #%00000011
:   pha                     ; Push BBC byte 1 (pixels 4-7) first (stack bottom)

    lda r7H                 ; BBC byte 0 (pixels 0-3)
    pha                     ; Push on top (stack top, popped first)

    ; Calculate BBC destination address
    ; dest = $3000 + char_row*640 + char_scan*80 + byte_n*2
    ;
    ; char_row * 640 = char_row * $0280
    lda r4L                 ; char_row
    beq skip_row_mul
    tax
    lda #0
    sta r6L
    sta r6H
:   clc
    lda #$80
    adc r6L
    sta r6L
    lda #$02
    adc r6H
    sta r6H
    dex
    bne :-
    jmp do_scan_add

skip_row_mul:
    lda #0
    sta r6L
    sta r6H

do_scan_add:
    ; Add char_scan * 80
    lda r5L
    beq skip_scan_mul
    tax
:   clc
    lda #80
    adc r6L
    sta r6L
    lda #0
    adc r6H
    sta r6H
    dex
    bne :-

skip_scan_mul:
    ; Add byte_n * 2
    lda r3L
    asl
    clc
    adc r6L
    sta r6L
    lda r6H
    adc #0
    sta r6H

    ; Add $3000 base
    clc
    lda r6H
    adc #$30
    sta r6H

    ; Write to screen memory
    ; Stack: [BBC byte 1] [BBC byte 0]  (byte 0 on top)
    ldy #0
    pla
    sta (r6L),y             ; BBC byte 0 (pixels 0-3)

    ; Move to next byte
    inc r6L
    bne :+
    inc r6H
:   pla
    sta (r6L),y             ; BBC byte 1 (pixels 4-7)

    rts

; ===========================================================
; Helper for string comparison
; ===========================================================
push_word:
    pha
    txa
    pha
    rts
