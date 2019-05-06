# make floppy
```
dd if=/dev/zero of=floppy.img bs=1k count=1440
losetup /dev/loop0 floppy.img
# fdisk /dev/loop0
mkdosfs /dev/loop0
# mkfs -t <fstype> /dev/loop5
mount -t vfat /dev/loop0 floppy
```
