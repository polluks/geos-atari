; BBC Micro hardware definitions
; for GEOS BBC port

; MC6845 CRTC
CRTC_ADDR       = $FE00
CRTC_DATA       = $FE01

; System VIA (6522)
SYSVIA          = $FE40
SYSVIA_ORB      = SYSVIA+0       ; Port B I/O
SYSVIA_ORA      = SYSVIA+1       ; Port A I/O
SYSVIA_DDRB     = SYSVIA+2       ; Port B data direction
SYSVIA_DDRA     = SYSVIA+3       ; Port A data direction
SYSVIA_T1CL     = SYSVIA+4       ; Timer 1 counter low
SYSVIA_T1CH     = SYSVIA+5       ; Timer 1 counter high
SYSVIA_T1LL     = SYSVIA+6       ; Timer 1 latch low
SYSVIA_T1LH     = SYSVIA+7       ; Timer 1 latch high
SYSVIA_T2CL     = SYSVIA+8       ; Timer 2 counter low
SYSVIA_T2CH     = SYSVIA+9       ; Timer 2 counter high
SYSVIA_SR       = SYSVIA+10      ; Shift register
SYSVIA_ACR      = SYSVIA+11      ; Auxiliary control register
SYSVIA_PCR      = SYSVIA+12      ; Peripheral control register
SYSVIA_IFR      = SYSVIA+13      ; Interrupt flag register
SYSVIA_IER      = SYSVIA+14      ; Interrupt enable register
SYSVIA_ORA_NH   = SYSVIA+15      ; Port A (no handshake)

; User VIA (6522)
USRVIA          = $FE60
USRVIA_ORB      = USRVIA+0
USRVIA_ORA      = USRVIA+1
USRVIA_DDRB     = USRVIA+2
USRVIA_DDRA     = USRVIA+3
USRVIA_T1CL     = USRVIA+4
USRVIA_T1CH     = USRVIA+5
USRVIA_T1LL     = USRVIA+6
USRVIA_T1LH     = USRVIA+7
USRVIA_T2CL     = USRVIA+8
USRVIA_T2CH     = USRVIA+9
USRVIA_SR       = USRVIA+10
USRVIA_ACR      = USRVIA+11
USRVIA_PCR      = USRVIA+12
USRVIA_IFR      = USRVIA+13
USRVIA_IER      = USRVIA+14
USRVIA_ORA_NH   = USRVIA+15

; Video ULA
VIDULA          = $FE20
VIDULA_CTL      = VIDULA+0       ; Control register
VIDULA_PALETTE  = VIDULA+1       ; Palette / cursor

; 6845 CRTC register indices
CRTC_R0 = 0     ; Horizontal Total
CRTC_R1 = 1     ; Horizontal Displayed
CRTC_R2 = 2     ; Horizontal Sync Position
CRTC_R3 = 3     ; Sync Width
CRTC_R4 = 4     ; Vertical Total
CRTC_R5 = 5     ; Vertical Total Adjust
CRTC_R6 = 6     ; Vertical Displayed
CRTC_R7 = 7     ; Vertical Sync Position
CRTC_R8 = 8     ; Interlace Mode
CRTC_R9 = 9     ; Max Scanline
CRTC_R10 = 10   ; Cursor Start
CRTC_R11 = 11   ; Cursor End
CRTC_R12 = 12   ; Start Address High
CRTC_R13 = 13   ; Start Address Low
CRTC_R14 = 14   ; Cursor Address High
CRTC_R15 = 15   ; Cursor Address Low
CRTC_R16 = 16   ; Light Pen High
CRTC_R17 = 17   ; Light Pen Low

; System VIA interrupt flags (IFR bits)
VIA_IFR_T1      = %01000000      ; Timer 1
VIA_IFR_T2      = %00100000      ; Timer 2
VIA_IFR_CB1     = %00010000      ; CB1
VIA_IFR_CB2     = %00001000      ; CB2
VIA_IFR_SR      = %00000100      ; Shift register
VIA_IFR_CA1     = %00000010      ; CA1
VIA_IFR_CA2     = %00000001      ; CA2
VIA_IFR_IRQ     = %10000000      ; Any IRQ

; Keyboard column strobes (VIA port B bits)
KBD_COL0 = %00000001
KBD_COL1 = %00000010
KBD_COL2 = %00000100
KBD_COL3 = %00001000
KBD_COL4 = %00010000
KBD_COL5 = %00100000
KBD_COL6 = %01000000

; Keyboard row inputs (VIA port A bits)
KBD_ROW_MASK = %01111111

; BBC memory map constants
BBC_SCREEN_BASE = $3000           ; Mode 1 screen base
BBC_SCREEN_SIZE = $2800           ; 10240 bytes for mode 1

; ROM entry constants
SERVICE_ENTRY   = $800A
LANG_ENTRY      = $8008

; Mode 1 screen address calculation:
; addr = BBC_SCREEN_BASE + (Y/8)*320 + (Y%8)*40 + X/4
; byte = (3 - (X%4)) * 2 bits

; Microseconds for 100Hz timer (2MHz CPU, 20000 cycles)
TIMER_100HZ     = 20000
; For VIA timer 1: count = (20ms * 2MHz) - 1 = 39999
; Actually VIA timer counts one more after loading, so: 40000 - 1 = 39999
T1_100HZ_LO     = <39999
T1_100HZ_HI     = >39999

; OS entry points
OSWRCH  = $FFEE
OSFIND  = $FFCE
OSBGET  = $FFCA
