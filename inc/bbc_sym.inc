; BBC Micro-specific symbol overrides for GEOS
; Override key memory map constants for the BBC port

; The BBC has no hardware sprites (VDC-style software sprites only)
; Override sprite-related addresses
MOUSE_SPRNUM            =       0

; Screen buffer moved to $7000 (linear framebuffer, 40*200=8000 bytes)
SCREEN_BASE             =       $7000
BACK_SCR_BASE           =       $7A00   ; back buffer in remaining space

; Kernel variables moved to $5800 area
OS_VARS                 =       $5800

; Font data area
SPRITE_PICS             =       $6A00   ; sprite picture data
COLOR_MATRIX            =       $6000   ; unused on BBC, repurposed for data

; The rest of the C64-specific addresses won't be used

; Override disk/variable addresses for BBC RAM layout
diskBlkBuf              =       $5900
fileHeader              =       $5A00
curDirHead              =       $5B00
fileTrScTab             =       $5C00
dirEntryBuf             =       $5D00
DrACurDkNm              =       $5E1E
DrBCurDkNm              =       $5E30
