;     Pong'ed      ;
;     A Game by Paul Yacobellis ;
;     Simple NES implementation of classic 'Pong game'
;

;;; Include Other scripts and constants
; include utils
; include constants
; include macros
; include 

; initialize iNES header
; 16 bytes we define at beginning of our NES asm code
; this code tells the emulator what type of software to run, and 
;    and cartridge settings for that software (i.e. battery, mappers, etc)
; i.e.  we want to tell the emulator to run NES game software

.segment "HEADER"   ; tells assembler we are entering HEADER section

.byte
.byte
.byte
.byte



; .segment "CODE"


; NMI
; 


