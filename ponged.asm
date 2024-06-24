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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;                            ZERO PAGE                                   ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            ZERO PAGE                                   ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            ZERO PAGE                                   ;;;;;;;                                          ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "ZEROPAGE"
Buttons:  .res 1
XPos:     .res 1
YPos:     .res 1
Frame:    .res 1
Clock60:  .res 1
BgPtr:    .res 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;                            CODE                                        ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            CODE                                        ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            CODE                                        ;;;;;;;                                          ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CODE"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;   Sub Routines                      ;;;;;;;
;;;;;;   Sub Routines                      ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc ReadControllers
    lda #1              ; A = 1
    sta Buttons         ; Buttons (in Zero Page) = 1 
    sta $4016           ; Set Latch = 1 to begin 'Input' collection mode
    lsr                 ; Set A = 0, shift A (currently %00000001) one to the right, making A %00000000.  Faster than lda #0.
    sta $4016           ; Set Latch = 0 to begin 'Output Mode'
LoopButtons:
    lda $4016           ; This reads a bit from the controller data line and inverts its value
                        ; And also send a signal to teh Clock line to shift the bits
    
    lsr                 ; We shift-right to place that 1-bit we just read in the Carry Flag
    rol Buttons         ; Rotate bits left, placign the Carry value into the first bit of 'Buttons' in RAM
    bcc LoopButtons     ; Loop until Carry is set (from the initial 1 we loaded inside Buttons)
    rts
.endproc

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;   Reset and Initialise Variables    ;;;;;;;
;;;;;;   REset and Initialise Variables    ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;; Reset System

RESET:
   INIT_NES      ; call initialisation macro from reset.inc
                 ; includes memory clear, vblank waits, etc.

InitVariables:
    lda #0
    sta Frame

    ldx #0
    lda SpriteData,x
    sta YPos
    ldx #3
    lda SpriteData,x
    sta XPos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;          Main                       ;;;;;;;
;;;;;;          Main                       ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;          NMI                        ;;;;;;;
;;;;;;          NMI                        ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


NMI:
    lda #$02    ; Each NMI, we copy sprite data from $02** to 
    sta $4014   ;  Start OAM DMA copy by writing to register 

    jsr ReadControllers

CheckDownButton:
    lda Buttons
    and #BUTTON_DOWN
    beq CheckUpButton
    inc YPos

CheckUpButton:
    lda Buttons
    and #BUTTON_UP
    beq :+        ; if not =0, branch to outside this label
    dec YPos
:

UpdateSpritePosition:   ; use this to update the sprite position
    lda XPos
    sta $0203 ; Set the 1st sprite X position to be XPos (connect positino to XPos)
    sta $020B ; Set the 3rd sprite X position to be XPos
    ;clc
    ;adc #8
    sta $0207  ; Set the 2nd sprite X position to be XPos
    sta $020F  ; Set the 4th sprite X position to be XPos
   
    lda YPos
    sta $0200      ; Set the 1st sprite Y position to be YPos
    clc
    adc #8   
    sta $0204     ; Set the 2nd sprite Y position to be YPos
    clc
    adc #8         
    sta $0208     ; Set the 3rd sprite Y position to be YPos + 16
    clc
    adc #8    
    sta $020C     ; Set the 4th sprite Y position to be YPos + 24

    lda Frame                ; Increment Clock60 every time we reach 60 frames (NTSC = 60Hz)
    cmp #60                  ; Is Frame equal to #60?
    bne :+                   ; If not, bypass Clock60 increment
    inc Clock60              ; But if it is 60, then increment Clock60 and zero Frame counter
    lda #0
    sta Frame
:


    rti   ; NMI rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;          IRQ                        ;;;;;;;
;;;;;;          IRQ                        ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


IRQ:
    rti  ; IRQ rti


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;          GRAPHICS DATA              ;;;;;;;
;;;;;;          GRAPHICS DATA              ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PaletteData:
.byte $0f,$2c,$14,$15, $0f,$0c,$21,$32, $0f,$05,$16,$27, $0f,$0b,$1a,$29
.byte $0f,$1c,$21,$32, $0f,$11,$22,$33, $0f,$12,$23,$34, $0f,$21,$14,$38

BackgroundData:
.incbin "pong_nametab.nam"

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;                            CHARS                                       ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            CHARS                                       ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            CHARS                                       ;;;;;;;                                          ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CHR-ROM Data
.segment "CHARS"
.incbin "ponged.chr"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;                            VECTORS                                     ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            VECTORS                                     ;;;;;;;                                          ;;;;;;;;
;;;;;;;;                            VECTORS                                     ;;;;;;;                                          ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "VECTORS" ; 6502 always need to go here when it gets powered on
;.org $FFFA        ; each vector is 16-bits.  So $FFFA + (16 x 3 bits) = $FFFF, the end of our PRG-ROM, end of the cartridge
.word NMI
.word RESET
.word IRQ



