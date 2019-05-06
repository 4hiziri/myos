#!/bin/bash
qemu-system-i386 -m 2 -localtime -vga std -fda floppy.img -monitor stdio
