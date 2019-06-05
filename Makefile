base_img = fat32.img
boot_img = boot_loader
boot_src = boot_fat32.asm
os_bin = myos
os_img = os.img
os_img_rand = os_rand.img
bootpack = src/c/bootpack.c
CSRC = src/c
ASRC = src/asm
OBJ = obj

$(os_img):	$(boot_img) $(os_bin)
	dd if=$(OBJ)/$(boot_img) of=$(OBJ)/$(os_img) conv=notrunc
	dd if=$(OBJ)/$(boot_img) of=$(OBJ)/$(os_img) bs=512 count=1 seek=6 conv=notrunc
	dd if=$(base_img) of=$(OBJ)/$(os_img) bs=512 count=1 skip=32 seek=32 conv=notrunc
	dd if=$(base_img) of=$(OBJ)/$(os_img) bs=512 count=1 skip=4128 seek=4128 conv=notrunc
	dd if=$(base_img) of=$(OBJ)/$(os_img) bs=512 count=1 skip=8224 seek=8224 conv=notrunc
	dd if=$(base_img) of=$(OBJ)/$(os_img) bs=512 count=1 skip=8240 seek=8240 conv=notrunc
	dd if=$(base_img) of=$(OBJ)/$(os_img) bs=512 count=10 skip=16400 seek=16400 conv=notrunc

	sudo mount $(OBJ)/$(os_img) /mnt
	sudo cp -f $(OBJ)/myos.sys /mnt
	sudo umount /mnt

# rand_img:	$(boot_img)
# 	dd if=$(boot_img) of=$(os_img_rand) conv=notrunc
# 	dd if=$(boot_img) of=$(os_img_rand) bs=512 count=1 seek=6 conv=notrunc
# 	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=32 seek=32 conv=notrunc
# 	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=4128 seek=4128 conv=notrunc
# 	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=8224 seek=8224 conv=notrunc
# 	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=8240 seek=8240 conv=notrunc
# 	dd if=$(base_img) of=$(os_img_rand) bs=512 count=10 skip=16400 seek=16400 conv=notrunc

base_img:
	dd iflag=fullblock if=/dev/zero of=$(OBJ)/$(base_img) conv=notrunc bs=4096 count=1048576
	mkfs.fat -n "MYOS32  " -i 0xffffffff -s 16 -S 512 -f 2 -h 2048 -F 32 $(OBJ)/$(base_img)
	cp -f $(OBJ)/$(base_img) $(OBJ)/$(os_img)

$(boot_img): $(ASRC)/$(boot_src)
	nasm -o $(OBJ)/boot_fat32.o $(ASRC)/$(boot_src)
	ld --format=binary --oformat=binary -T linker-script/boot_loader.lds $(OBJ)/boot_fat32.o -o $(OBJ)/$(boot_img)

$(os_bin): $(ASRC)/myos.asm $(CSRC)/bootpack.c $(ASRC)/libfunc.asm
	nasm -o $(OBJ)/myos.o $(ASRC)/myos.asm
	nasm -felf32 -o $(OBJ)/libfunc.o $(ASRC)/libfunc.asm
	gcc -fno-pic -m32 -nostdlib -Wl,--oformat=binary -c -o $(OBJ)/bootpack.o $(CSRC)/bootpack.c
	ld -m elf_i386 -e HariMain --oformat=binary -o $(OBJ)/bootpack.bin $(OBJ)/bootpack.o $(OBJ)/libfunc.o
	cat $(OBJ)/myos.o $(OBJ)/bootpack.o > $(OBJ)/myos.sys

run:
	qemu-system-i386 -gdb tcp::30012 -m 2 -localtime -vga std -hda $(OBJ)/$(os_img) -monitor stdio

debug:
	qemu-system-i386 -gdb tcp::30012 -m 2 -localtime -vga std -hda $(OBJ)/$(os_img) -monitor stdio -S
