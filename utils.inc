
; macro to set 16 bit address to ppu address register
.macro PPU_SETADDR addr
    bit PPU_STATUS
    lda #>addr
    sta PPU_ADDR
    lda #<addr
    sta PPU_ADDR
.endmacro

; macro to send a value to the PPU_DATA (at $2007)
.macro PPU_SETDATA val
    lda val
    sta PPU_DATA
.endmacro