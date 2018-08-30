floppy.img:	boot32.img
	dd if=boot32.img bs=512 count=1 of=floppy.img conv=notrunc

boot32.img:	boot_fat32.asm
	nasm boot_fat32.asm -o boot32.img

