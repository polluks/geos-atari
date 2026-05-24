; BBC Micro bank call stubs
; For BBC (no banking), these just route directly to the implementations

.segment "bank_jmptab_front"

.import __HorizontalLine, __InvertLine, __RecoverLine, __VerticalLine
.import __Rectangle, __FrameRectangle, __InvertRectangle, __RecoverRectangle
.import __DrawLine, __DrawPoint, __GetScanLine, __TestPoint
.import __ImprintRectangle
.import __Dabs, __Dnegate
.import __InitTextPrompt, __PromptOn, __PromptOff
.import __SetPattern
.import __ToBASIC
.import __DoUpdateTimeSeconds

.global _HorizontalLine, _InvertLine, _RecoverLine, _VerticalLine
.global _Rectangle, _FrameRectangle, _InvertRectangle, _RecoverRectangle
.global _DrawLine, _DrawPoint, _GetScanLine, _TestPoint
.global _ImprintRectangle
.global _Dabs, _Dnegate
.global _InitTextPrompt, _PromptOn, _PromptOff
.global _SetPattern
.global _ToBASIC
.global _DoUpdateTimeSeconds
.global _GetSerialNumber

_HorizontalLine:   jmp __HorizontalLine
_InvertLine:       jmp __InvertLine
_RecoverLine:      jmp __RecoverLine
_VerticalLine:     jmp __VerticalLine
_Rectangle:        jmp __Rectangle
_FrameRectangle:   jmp __FrameRectangle
_InvertRectangle:  jmp __InvertRectangle
_RecoverRectangle: jmp __RecoverRectangle
_DrawLine:         jmp __DrawLine
_DrawPoint:        jmp __DrawPoint
_GetScanLine:      jmp __GetScanLine
_TestPoint:        jmp __TestPoint
_ImprintRectangle: jmp __ImprintRectangle
_Dabs:             jmp __Dabs
_Dnegate:          jmp __Dnegate
_InitTextPrompt:   jmp __InitTextPrompt
_PromptOn:         jmp __PromptOn
_PromptOff:        jmp __PromptOff
_SetPattern:       jmp __SetPattern
_ToBASIC:          jmp __ToBASIC
_DoUpdateTimeSeconds: jmp __DoUpdateTimeSeconds
; For BBC, implement GetSerialNumber inline since serial2.s is not included
_GetSerialNumber:
    lda #0
    tax
    rts
