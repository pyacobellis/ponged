.macro INIT_NES
    sei             ; Disable all IRQ interupt requests - housekeeping on reset
    cld             ; clear decimal mode (unused) - - housekeeping on reset
    ldx #$FF
    txs             ; initialise stack pointer at $01FF
    
    inx             ; x is now 0  
    stx PPU_CTRL  ; disable NMI
    stx PPU_MASK  ; disable rendering
    stx $4010      ; disable DMC IRQs
    
    lda #$40
    sta $4017
    
     


    lda #0          ; A = 0
    ldx #0          ; X = x = $0 - start with 0 - after dex, will wrap to $FF

VblankWait1:
    bit PPU_STATUS         ; checks sign, if pos (not in Vblank), in continue loop
    bpl VblankWait1   ; if neg (in Vblank), exit loop

; clear memory on system reset
MemLoop:
    sta $0, x      ; Store teh value of A (zero) into address $0 + X
    dex            ; X--
    bne MemLoop    ; If X is not zero, loop back to MemLoop label

;TODO: clear all memory, not just Zero Page


    lda #0
ClearRAM:
    sta $000, x
    sta $100, x
    sta $200, x
    sta $300, x
    sta $400, x
    sta $500, x
    sta $600, x
    sta $700, x
    sta $800, x
    inx
    bne ClearRAM

VblankWait2:
    bit PPU_STATUS       ; checks sign, if pos, in continue loop
    bpl VblankWait2   ; if neg (VblankWait), exit loop

.endmacro   ; END MACRO