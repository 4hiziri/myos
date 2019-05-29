#!/bin/bash
qemu-system-i386 -gdb tcp::30012 -m 2 -localtime -vga std -hda "$@" -monitor stdio
