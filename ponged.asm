;     Pong'ed      ;
;     Hatfield Games;
;     Simple NES implementation of classic 'Pong game'
;

;;; Include Other scripts and constants
; include utils
.include "constants.inc"
.include "header.inc"
.include "reset.inc"
.include "utils.inc"

.segment "ZEROPAGE"
Frame:    .res 1
Clock60:  .res 1
BgPtr:    .res 2



.segment "CODE"

.proc LoadPalette
    PPU_SETADDR $3F00
    ldy #0
:   lda PaletteData, y
    sta PPU_DATA          ; Set value to send to PPU_DATA
    iny 
    cpy #32
    bne :-
    rts
.endproc

.proc LoadSprites
    ldx #0
LoadSprites:
    lda SpriteData,x
    sta $0200,x
    inx 
    cpx #36
    bne LoadSprites
    rts
.endproc


.proc LoadBackground
    lda #<BackgroundData
    sta BgPtr
    lda #>BackgroundData
    sta BgPtr+1

    PPU_SETADDR $2000

    ldx #$00
    ldy #$00

    OuterLoop:
    InnerLoop:
        lda (BgPtr),y            ; Fetch the value *pointed* by BgPtr + Y
        sta PPU_DATA             ; Store in the PPU data
        iny                      ; Y++
        cpy #0                   ; If Y == 0 (wrapped around 256 times)?
        beq IncreaseHiByte       ;   Then: we need to increase the hi-byte
        jmp InnerLoop            ;   Else: Continue with the inner loop
    IncreaseHiByte:
        inc BgPtr+1              ; We increment the hi-byte pointer to point to the next background section (next 255-chunk)
        inx                      ; X++
        cpx #4                   ; Compare X with #4
        bne OuterLoop            ;   If X is still not 4, then we keep looping back to the outer loop

        rts                      ; Return from subroutine
.endproc

.proc LoadAttributes
    PPU_SETADDR $23C0
    ldy #0
:   lda AttributeData,y
    sta PPU_DATA
    iny
    cpy #16
    bne :-
    rts
.endproc    


RESET:
   INIT_NES      ; call initialisation macro from reset.inc
                 ; includes memory clear, vblank waits, etc.

InitVariables:
    lda #0
    sta Frame


    Main:

    jsr LoadPalette
    jsr LoadBackground
    jsr LoadAttributes
    jsr LoadSprites
    
EnablePPURendering:
    lda #%10000000
    sta PPU_CTRL
    lda #0
    sta PPU_SCROLL
    sta PPU_SCROLL
    lda #%00011110
    sta PPU_MASK

LoopForever:
    jmp LoopForever

NMI:
    lda #$02    ; Each NMI, we copy sprite data from $02** to 
    sta $4014   ;  Start OAM DMA copy by writing to register 
    rti   ; rti = Return From Interupt
IRQ:
    rti


; GRAPHICS DATA
PaletteData:
.byte $0f,$2c,$14,$15, $0f,$0c,$21,$32, $0f,$05,$16,$27, $0f,$0b,$1a,$29
.byte $0f,$1c,$21,$32, $0f,$11,$22,$33, $0f,$12,$23,$34, $0f,$21,$14,$38



BackgroundData:
.incbin "pong_nametab.nam"
    ; .byte $01,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$03
	; .byte $11,$46,$55,$55,$55,$55,$55,$55,$12,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$11
	; .byte $11,$46,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$11
	; .byte $11,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$11
	; .byte $11,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$11
	; .byte $11,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$11
	; .byte $11,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$12,$12,$12,$12,$12,$12,$55,$55,$11
	; .byte $11,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$12,$12,$12,$12,$55,$55,$55,$55,$55,$55,$55,$55,$55,$12,$12,$12,$12,$55,$11

AttributeData:
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

SpriteData:
;           Y     tile#    attribs      X
.byte     120,     $04,    %00000000,   $18
.byte     128,     $10,    %00000000,   $18
.byte     136,     $10,    %00000000,   $18
.byte     144,     $04,    %10000000,   $18
.byte     80,     $04,    %00000000,   $DF
.byte     88,     $10,    %00000000,   $DF
.byte     96,     $10,    %00000000,   $DF
.byte     104,    $04,    %10000000,   $DF
.byte     130,    $05,    %00000110,   $A9

; CHR-ROM Data
.segment "CHARS"
.incbin "ponged.chr"

.segment "VECTORS" ; 6502 always need to go here when it gets powered on
;.org $FFFA        ; each vector is 16-bits.  So $FFFA + (16 x 3 bits) = $FFFF, the end of our PRG-ROM, end of the cartridge
.word NMI
.word RESET
.word IRQ
; NMI
; RESET


