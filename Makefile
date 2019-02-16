floppy.img:	boot32.img
	dd if=boot32.img of=floppy.img conv=notrunc
	dd if=boot32.img of=floppy.img bs=512 count=1 seek=6 conv=notrunc

boot32.img:	boot_fat32.asm
	nasm boot_fat32.asm -o boot32.img

