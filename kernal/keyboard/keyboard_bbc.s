; GEOS KERNAL for BBC Micro
; Keyboard scan driver

; BBC Micro keyboard matrix:
; Column lines (VIA PB0-PB6):
;   PB0=Col0, PB1=Col1, ..., PB6=Col6
; Row lines (VIA PA0-PA6):
;   PA0=Row0..PA6=Row6, PA7=not used for keyboard

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "bbc.inc"

.import KbdQueHead
.import KbdQueTail
.import KbdQueFlag
.import KbdQueue

.global _DoKeyboardScan
.global _GetNextChar

.segment "keyboard1"

; Scan keyboard matrix
; For each column, strobe it low and read rows
_DoKeyboardScan:
    ; Save registers
    pha
    txa
    pha
    tya
    pha

    ; Scan all 7 columns
    ldx #0                  ; Start with column 0
    ; Column strobe value: all 1s, then clear bit X
    lda #%01111111          ; All columns high initially
    sta col_strobe

scan_next_col:
    ; Set column strobe
    lda col_strobe
    and col_mask,x
    sta SYSVIA_ORB

    ; Small delay for signals to settle
    nop
    nop

    ; Read rows
    lda SYSVIA_ORA
    and #KBD_ROW_MASK      ; Only bits 0-6 are row inputs
    sta row_data

    ; Check if any key pressed in this column
    cmp #%01111111          ; All rows high = no key
    beq next_column

    ; A key is pressed - find which row
    ldy #0                  ; Row counter

find_row:
    lda row_data
    and row_mask,y
    beq key_found           ; Row is low = key pressed
    iny
    cpy #7
    bne find_row
    beq next_column

key_found:
    ; Found key at column X, row Y
    ; Look up keycode from matrix table
    txa                     ; Save X (column)
    pha
    tya
    pha

    ; Get the keycode from the matrix
    sty row_save
    txa
    asl                     ; *8
    asl
    asl
    clc
    adc row_save            ; + Y (row)
    tay
    lda key_matrix,y
    ; Check if key is valid (non-zero)
    beq key_done

    ; Queue the key
    ; KbdQueue is a 16-byte FIFO
    ldy KbdQueHead
    sty KbdQueTail
    sta KbdQueue,y
    inc KbdQueHead
    lda #16
    cmp KbdQueHead
    bne :+
    lda #0
    sta KbdQueHead
:   lda #$FF
    sta KbdQueFlag

key_done:
    pla
    tay
    pla
    tax
    bne next_column

next_column:
    inx
    cpx #7
    bne scan_next_col

    ; Restore all columns high
    lda #%01111111
    sta SYSVIA_ORB

    pla
    tay
    pla
    tax
    pla
    rts

; Column mask table
col_mask:
    .byte %11111110         ; Column 0 (PB0)
    .byte %11111101         ; Column 1 (PB1)
    .byte %11111011         ; Column 2 (PB2)
    .byte %11110111         ; Column 3 (PB3)
    .byte %11101111         ; Column 4 (PB4)
    .byte %11011111         ; Column 5 (PB5)
    .byte %10111111         ; Column 6 (PB6)

; Row mask table
row_mask:
    .byte %00000001         ; Row 0 (PA0)
    .byte %00000010         ; Row 1 (PA1)
    .byte %00000100         ; Row 2 (PA2)
    .byte %00001000         ; Row 3 (PA3)
    .byte %00010000         ; Row 4 (PA4)
    .byte %00100000         ; Row 5 (PA5)
    .byte %01000000         ; Row 6 (PA6)

; Temporary storage
col_strobe: .byte 0
row_data:   .byte 0
row_save:   .byte 0

; BBC Micro keyboard matrix (columns 0-6, rows 0-6)
; These are the standard keycodes (ASCII or GEOS key values)
; A zero entry means no key at that position.
;
; Column layout (typical BBC keyboard):
; Col 0: 1 2 3 4 5 6 7
; Col 1: 8 9 0 - ^ ! |
; Col 2: Q W E R T Y U
; Col 3: I O P @ _ * ?
; Col 4: A S D F G H J
; Col 5: K L ; : ] [ \
; Col 6: Z X C V B N M
;
; Row mapping:
; Row 0 (top), Row 6 (bottom)
;
; Simplified matrix for proof of concept
key_matrix:
    ; Col 0: keys 1-7
    .byte '1', '2', '3', '4', '5', '6', '7'
    ; Col 1: keys 8-0 and symbols
    .byte '8', '9', '0', '-', '^', '!', '|'
    ; Col 2: Q-U
    .byte 'Q', 'W', 'E', 'R', 'T', 'Y', 'U'
    ; Col 3: I-O and symbols  
    .byte 'I', 'O', 'P', '@', '_', '*', '?'
    ; Col 4: A-J
    .byte 'A', 'S', 'D', 'F', 'G', 'H', 'J'
    ; Col 5: K-\ and symbols
    .byte 'K', 'L', ';', ':', ']', '[', $5C
    ; Col 6: Z-M
    .byte 'Z', 'X', 'C', 'V', 'B', 'N', 'M'

; Shift, Control, and other special keys are not mapped for proof of concept.
; They would need additional column scanning.

_GetNextChar:
    ; Read next key from keyboard queue
    lda KbdQueFlag
    beq no_key
    ldy KbdQueTail
    lda KbdQueue,y
    pha
    inc KbdQueTail
    lda #16
    cmp KbdQueTail
    bne :+
    lda #0
    sta KbdQueTail
:   lda KbdQueTail
    cmp KbdQueHead
    bne :+
    lda #0
    sta KbdQueFlag
:   pla
    rts
no_key:
    lda #0
    rts
