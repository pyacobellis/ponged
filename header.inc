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
