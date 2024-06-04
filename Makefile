build:
	ca65 ponged.asm -o ponged.o
	ld65 -C nes.cfg ponged.o -o ponged.nes