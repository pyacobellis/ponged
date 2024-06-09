;     Pong'ed      ;
;     Hatfield Games;
;     Simple NES implementation of classic 'Pong game'
;

;;; Include Other scripts and constants
; include utils
.include "constants.inc"
.include "header.inc"
.include "reset.inc"


; include macros
; include 



.segment "CODE"

.proc LoadPalette:
:
    lda PaletteData, y
    sta PPU_DATA          ; Set value to send to PPU_DATA
    iny 
    cpy #32
    bne :-
    rts
.endproc


.proc LoadBackground:
    ldy
:
    lda PaletteData, y
    sta PPU_DATA          ; Set value to send to PPU_DATA
    iny 
    cpy #32
    bne :-
    rts
.endproc

RESET:
   INIT_NES      ; call initialisation macro from reset.inc
                 ; includes memory clear, vblank waits, etc.

Main:
    bit PPU_STATUS  ; Reset latch of PPU_ADDR  to hi-byte 
    ldx #$3F
    stx PPU_ADDR  ; Set hi-byte of PPU_ADDR to $3F
    ldx #$00
    stx PPU_ADDR ; Set low-bit of PPU_ADDR to $00
    
    ldy #0

    jsr LoadPalette


    bit PPU_STATUS  ; Reset latch of PPU_ADDR  to hi-byte 
    ldx #$3F
    stx PPU_ADDR  ; Set hi-byte of PPU_ADDR to $3F
    ldx #$00
    stx PPU_ADDR ; Set low-bit of PPU_ADDR to $00
    
    jsr LoadBackground

    lda #%00011110
    sta PPU_MASK        ; Set PPU_MASK bits to show background


LoopForever:
    jmp LoopForever

NMI:
    rti   ; rti = Return From Interupt
IRQ:
    rti


; GRAPHICS DATA
PaletteData:
.byte $0f,$00,$10,$04, $0f,$0c,$21,$21, $0f,$05,$16,$24, $0f,$0b,$1a,$29 ; Background
.byte $0f,$00,$10,$04, $0f,$0c,$21,$21, $0f,$05,$16,$24, $0f,$0b,$1a,$29 ; Sprite


; CHR-ROM Data
.segment "CHARS"
.incbin "pong_bkgrd.chr"

.segment "VECTORS" ; 6502 always need to go here when it gets powered on
;.org $FFFA        ; each vector is 16-bits.  So $FFFA + (16 x 3 bits) = $FFFF, the end of our PRG-ROM, end of the cartridge
.word NMI
.word RESET
.word IRQ
; NMI
; RESET


