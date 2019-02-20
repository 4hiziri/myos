floppy.img:	boot32.img
	dd if=boot32.img of=floppy.img conv=notrunc
	dd if=boot32.img of=floppy.img bs=512 count=1 seek=6 conv=notrunc
	dd if=fat32.img of=floppy.img bs=512 count=1 skip=32 seek=32 conv=notrunc
	dd if=fat32.img of=floppy.img bs=512 count=1 skip=4128 seek=4128 conv=notrunc
	dd if=fat32.img of=floppy.img bs=512 count=1 skip=8224 seek=8224 conv=notrunc

boot32.img:	boot_fat32.asm
	nasm boot_fat32.asm -o boot32.img

