base_img = fat32.img
boot_img = boot32.img
boot_src = boot_fat32.asm
os_img = floppy.img
os_img_rand = floppy_rand.img

$(os_img):	$(boot_img)
	dd if=$(boot_img) of=$(os_img) conv=notrunc
	dd if=$(boot_img) of=$(os_img) bs=512 count=1 seek=6 conv=notrunc
	dd if=$(base_img) of=$(os_img) bs=512 count=1 skip=32 seek=32 conv=notrunc
	dd if=$(base_img) of=$(os_img) bs=512 count=1 skip=4128 seek=4128 conv=notrunc
	dd if=$(base_img) of=$(os_img) bs=512 count=1 skip=8224 seek=8224 conv=notrunc
	dd if=$(base_img) of=$(os_img) bs=512 count=1 skip=8240 seek=8240 conv=notrunc
	dd if=$(base_img) of=$(os_img) bs=512 count=10 skip=16400 seek=16400 conv=notrunc

rand_img:	$(boot_img)
	dd if=$(boot_img) of=$(os_img_rand) conv=notrunc
	dd if=$(boot_img) of=$(os_img_rand) bs=512 count=1 seek=6 conv=notrunc
	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=32 seek=32 conv=notrunc
	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=4128 seek=4128 conv=notrunc
	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=8224 seek=8224 conv=notrunc
	dd if=$(base_img) of=$(os_img_rand) bs=512 count=1 skip=8240 seek=8240 conv=notrunc
	dd if=$(base_img) of=$(os_img_rand) bs=512 count=10 skip=16400 seek=16400 conv=notrunc

$(boot_img):	$(boot_src)
	nasm $(boot_src) -o $(boot_img)
