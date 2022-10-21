; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Panic

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.warning "panic1.s - untested (directly nor via BRK)"

.segment "panic1"

.import DoDlgBox
.import Ddec
.import EnterDeskTop

; syscall
.global _Panic

;---------------------------------------------------------------
; Panic                                                   $C2C2
;
; Pass:      nothing
; Return:    does not return
;---------------------------------------------------------------
_Panic:
	PopW r0
	SubVW 2, r0		; restore caller address
	lda r0H
	ldx #0
	jsr hex2digit
	lda r0L
	jsr hex2digit
	LoadW r0, _PanicDB_DT
	jsr DoDlgBox
	jmp EnterDeskTop

hex2digit:
	pha
	lsr
	lsr
	lsr
	lsr
	jsr hexdigit
	inx
	pla
	and #%00001111
	jsr hexdigit
	inx
	rts

hexdigit:
	cmp #10
	bcs :+
	addv '0'
	bne :++
:	addv '0'+7
:	sta _PanicAddr,x
	rts

.segment "panic2"

_PanicDB_DT:
	.byte DEF_DB_POS | 1
	.byte DBTXTSTR, TXT_LN_X, TXT_LN_1_Y
	.word _PanicDB_Str
	.byte NULL

.segment "panic3"

_PanicDB_Str:
	.byte BOLDON
	.byte "Error near "
	.byte "System error near "
	.byte "$"
_PanicAddr:
	.byte "xxxx"
	.byte NULL
