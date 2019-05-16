#!/bin/bash
qemu-system-i386 -S -gdb tcp::30012 -m 2 -localtime -vga std -hda "$1" -monitor stdio
