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
    .byte $40                   ; ROM type: service entry only
    .byte $01                   ; version 0.1
    .byte "GEOS", $00           ; null-terminated title

; ===========================================================
; Service entry - called by MOS
; ===========================================================
.segment "start"
rom_service:
    cpy #$04                ; *command? (some MOS versions)
    beq check_command
    cpy #$09                ; *command? (MOS 1.20+)
    beq check_command
    cpy #$08                ; *HELP?
    beq help_command
    rts

help_command:
    ; Print ROM name for *HELP
    pha
    ldx #0
:   lda help_text,x
    beq :+
    jsr $FFEE               ; OSWRCH
    inx
    bne :-
:   pla
    rts

check_command:
    pla                     ; pop return addr low
    sta r0L
    pla                     ; pop return addr high
    sta r0H
    jsr skip_spaces
    ldy #0
:   lda cmd_geos,y
    beq match_cmd
    cmp (r0L),y
    bne not_match
    iny
    bne :-
not_match:
    rts

match_cmd:
    pla                     ; discard return addr from skip_spaces
    pla
    ; fall through to _ResetHandle

help_text:
    .byte "GEOS KERNAL for BBC", 13, 10, 0

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

    ; Clear BSS area ($5800-$77FF)
    lda #0
    ldx #0
:   sta $5800,x
    sta $5A00,x
    sta $5C00,x
    sta $5E00,x
    sta $6000,x
    sta $6200,x
    sta $6400,x
    sta $6600,x
    sta $6800,x
    sta $6A00,x
    sta $6C00,x
    sta $6E00,x
    sta $7000,x
    sta $7200,x
    sta $7400,x
    sta $7600,x
    inx
    bne :--

    ; Init GEOS kernel
    jsr InitGEOEnv
    jsr MouseInit

    ; Draw to linear framebuffer at $7000
    jsr draw_desktop

    ; Convert framebuffer to BBC mode 1 screen format
    jsr fb_to_screen

    ; Halt
    cli
:   jmp :-

cmd_geos:
    .byte "GEOS", 0

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

    ; Set CRTC for mode 1 (320x256, 4 colors)
    ; R0=63, R1=40, R2=52, R3=14, R4=38, R5=0, R6=32
    ; R7=37, R8=32, R9=7

    ldx #0
crtc_loop:
    lda crtc_regs,x
    sta CRTC_ADDR
    inx
    lda crtc_regs,x
    sta CRTC_DATA
    inx
    cpx #20                 ; 10 registers * 2 bytes
    bne crtc_loop

    ; Set Video ULA for mode 1
    lda #%00000001
    sta VIDULA_CTL

    ; Clear screen to black
    lda #0
    ldx #0
:   sta $3000,x
    inx
    bne :-
:   sta $4000 - 1,x
    dex
    bne :-

    rts

crtc_regs:
    .byte CRTC_R0, 63
    .byte CRTC_R1, 40
    .byte CRTC_R2, 52
    .byte CRTC_R3, 14
    .byte CRTC_R4, 38
    .byte CRTC_R5, 0
    .byte CRTC_R6, 32
    .byte CRTC_R7, 37
    .byte CRTC_R8, 32      ; interlace
    .byte CRTC_R9, 7       ; 8 scanlines per char row

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
    ; Source = $7000 + Y * 40 + byte_n
    lda r2L
    sta r1L
    lda #0
    sta r1H
    ; Multiply r1 by 40 using shifts: *32 + *8
    lda r1L
    asl                     ; *2
    asl                     ; *4
    asl                     ; *8
    sta r0L
    lda r1L
    asl                     ; *2
    asl                     ; *4
    asl                     ; *8
    asl                     ; *16
    asl                     ; *32
    clc
    adc r0L
    sta r0L                 ; r0L = low byte of Y*40
    lda #0
    rol                     ; carry -> high byte
    sta r0H

    ; Add byte counter (r3L)
    clc
    lda r0L
    adc r3L
    sta r0L
    lda r0H
    adc #0
    sta r0H

    ; Add $7000 base
    clc
    lda r0H
    adc #$70
    sta r0H

    ldy #0
    lda (r0L),y             ; Read GEOS byte
    sta r7L                 ; geos_byte

    ; Convert to BBC format
    ; Pixel 0 (bit 7): output bits 7-6 = %11 if set
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
:   pha                     ; Push BBC byte 0

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
:   pha                     ; Push BBC byte 1

    ; Calculate BBC destination address
    ; dest = $3000 + char_row*320 + char_scan*40 + byte_n*2
    ; char_row*320 = char_row*256 + char_row*64
    lda r4L                 ; char_row
    beq skip_row_mul
    tax
    lda #0
    sta r6L
    sta r6H
:   clc
    lda #$40
    adc r6L
    sta r6L
    lda #$01
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
    ; Add char_scan * 40
    lda r5L
    beq skip_scan_mul
    tax
:   clc
    lda #40
    adc r6L
    sta r6L
    lda #0
    adc r6H
    sta r6H
    dex
    bne :-

skip_scan_mul:
    ; Add byte_n * 2 to dest
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
    ldy #0
    pla
    sta (r6L),y             ; BBC byte 1 (from stack, pushed second)

    ; Move to next byte in BBC format
    inc r6L
    bne :+
    inc r6H
:   pla
    sta (r6L),y             ; BBC byte 0

    rts

; ===========================================================
; Helper for string comparison
; ===========================================================
push_word:
    pha
    txa
    pha
    rts
