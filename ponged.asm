;     Pong'ed      ;
;     Hatfield Games;
;     Simple NES implementation of classic 'Pong game'
;

;;; Include Other scripts and constants
; include utils
; include constants

PPU_CTRL = $2000
PPU_MASK = $2001
PPU_STATUS = $2002
OAM_ADDR = $2003
OAM_DATA = $2004 
PPU_SCROLL = $2005
PPU_ADDR = $2006
PPU_DATA = $2007

; include macros
; include 

; initialize iNES header
; 16 bytes we define at beginning of our NES asm code
; this code tells the emulator what type of software to run, and 
;    and cartridge settings for that software (i.e. battery, mappers, etc)
; i.e.  we want to tell the emulator to run NES game software

.segment "HEADER"         ; tells assembler we are entering HEADER section
;.org $7FF0                ; start header at memory address $7FF0
.byte $4E, $45, $53, $1A  ; Flag 0-3:  ascii spelling of 'N', 'E', 'S', and '\n' (new line) 
.byte $02                 ; Flag 4: standard NROM: how many 16kb units we will use (32 = 16x2)
.byte $01                 ; Flag 5:  how many kbs (1) of CHR-ROM we will use
.byte %00000000           ; Flag 6:  details on mapper, battery pack, mirroring, etc
.byte %00000000           ; Flag 7:  other details on NES 2.0, other things
.byte $00                 ; Flag 8:  use PRG-ROM
.byte $00                 ; Flag 10:  set to NTSC format (not PAL)
.byte $00                 ;  No PRG-RAM
.byte $00, $00, $00, $00, $00 ; unused padding to fill 16 bytes of data


.segment "CODE"
RESET:
    sei             ; Disable all IRQ interupt requests - housekeeping on reset
    cld             ; clear decimal mode (unused) - - housekeeping on reset
    ldx #$40
    stx $4017
    
    ldx #$FF
    txs             ; Initalize stack pointer at $01FF
    inx             ; x is now 0  
    stx PPU_CTRL  ; disable NMI
    stx PPU_MASK  ; disable rendering
    stx $4010      ; disable DMC IRQs


    lda #0          ; A = 0
    ldx #0          ; X = x = $0 - start with 0 - after dex, will wrap to $FF

; clear memory on system reset
MemLoop:
    sta $0, x      ; Store teh value of A (zero) into address $0 + X
    dex            ; X--
    bne MemLoop    ; If X is not zero, loop back to MemLoop label

;TODO: clear all memory, not just Zero Page

$80, 
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

Main:
    ldx #$3F
    stx PPU_ADDR  ; Set hi-byte of PPU_ADDR to $3F
    ldx #$00
    stx PPU_ADDR ; Set low-bit of PPU_ADDR to $00
    lda #$2A
    sta PPU_MASK ; Send $2A (lime green color code) to PPU_DATA ($2007)
    lda #%00011110
    sta $2001           ; Set PPU_MASK bits to show background


LoopForever:
    jmp LoopForever

NMI:
    rti   ; rti = Return From Interupt
IRQ:
    rti

.segment "VECTORS" ; 6502 always need to go here when it gets powered on
;.org $FFFA        ; each vector is 16-bits.  So $FFFA + (16 x 3 bits) = $FFFF, the end of our PRG-ROM, end of the cartridge
.word NMI
.word RESET
.word IRQ
; NMI
; RESET


