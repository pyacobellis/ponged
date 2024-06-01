

.segment "CODE"
.org $8000
    sei

    lda #0     ; set A to zero, b/c want to set all zero page address values to zero
    ldx #$FF   ;  set X to FF, this will be our zero page memory address

MemLoop:
    sta $00, X
    dex
    bne MemLoop