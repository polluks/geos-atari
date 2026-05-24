; BBC Micro DFS loader for GEOS
; Uses OS file calls to load "DESKTOP" from disk
;
; OS entry points:
;   OSFIND = $FFCE  (A=$40 open input, XY=filename; returns A=handle)
;   OSBGET = $FFCA  (X=handle; returns A=byte, C=0 if OK)
;   OSFIND = $FFCE  (A=$00 close, X=handle)

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "bbc.inc"

.global _EnterDeskTop
.global DeskTopName

.segment "load1a"

_EnterDeskTop:
    ; Try to open "DESKTOP" via OSFIND
    lda #<desktop_filename
    ldx #>desktop_filename
    ldy #$40                ; open for input
    jsr OSFIND
    cmp #0
    beq load_failed

    sta fd                  ; save file handle

    ; Read file size from DFS directory info
    ; For now, load whole file to a buffer and parse GEOS header

    ; Read file header first (need load/exec addresses)
    ; GEOS file header is embedded in the file data
    ; For DESKTOP.cvt, the first bytes are the CBM-style directory entry
    ; followed by the GEOS header, then VLIR data

    ; We'll use a temporary buffer at APP_RAM start
    lda #<load_buffer
    sta r0L
    lda #>load_buffer
    sta r0H

    ; Read bytes from file into buffer
    ldx fd
read_loop:
    jsr OSBGET
    bcs read_done            ; C=1 means EOF
    sta (r0L),y
    iny
    bne read_loop
    inc r0H
    bra read_loop

read_done:
    ; File is now in load_buffer
    ; Parse GEOS header at offset 254 (after CBM directory entry)
    lda #<load_buffer
    sta r2L
    lda #>load_buffer
    sta r2H

    ; Close file
    lda #0
    ldx fd
    jsr OSFIND

    ; Extract VLIR records and load to correct addresses
    jmp parse_and_load

load_failed:
    ; Desktop not found - enter basic or loop
    ; For now, just return (back to MOS)
    rts

desktop_filename:
    .byte "DESKTOP", 0

fd:
    .res 1

load_buffer:
    .res 256                ; small test buffer for now

parse_and_load:
    ; TODO: full VLIR parsing
    rts

OSFIND = $FFCE
OSBGET = $FFCA
