; BBC Micro sprite stub - software sprites (VDC-style)
; For proof of concept, all sprite operations are no-ops
; Real implementation would save/restore background under sprites

.include "config.inc"
.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "kernal.inc"
.include "bbc.inc"

; syscalls
.global _DisablSprite
.global _DrawSprite
.global _EnablSprite
.global _PosSprite
.global AtariPlayersInit
.global curYSize

.segment "sprites"

; No hardware sprites on BBC - these are stubs
; In a real implementation, we'd use software-rendered sprites
; that save/restore background, like the VDC version does

curYSize:	.res 4

_DisablSprite:
	rts

_DrawSprite:
	rts

_EnablSprite:
	rts

_PosSprite:
	rts

AtariPlayersInit:
	rts

; Minimal panic stub (panic.s not included for BBC)
.global _Panic
_Panic:
	rts
