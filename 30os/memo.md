[BIOS introduction pages](http://community.osdev.info/?(AT)BIOS)

[available memory](http://community.osdev.info/?(AT)BIOS)

0x7c00 - 0x7dff: for boot sector

[es:bs] = es * 16 + bs

show color
```asm: os.asm
	ORG 0xc200

	MOV al, 0x13 ;; VGA graphics,320x200x8bit color
	MOV ah, 0x00
	int 0x10

fin:
	HLT
	JMP fin
```

check keyboard in BIOS
```asm: os.asm
	CYLS EQU 0x0ff0
	LEDS EQU 0x0ff1
	VMODE EQU 0x0ff2 ;; color's num of bit
	SCRNX EQU 0x0ff4 ;; screen X, pixel
	SCRNY EQU 0x0ff6 ;; screen Y, pixel
	VRAM EQU 0x0ff8  ;; graphics buff
	
	ORG 0xc200
	
	MOV al, 0x13 ;; VGA mode
	MOV ah, 0x00
	INT 0x10
	MOV BYTE [VMODE], 8
	MOV WORD [SCRNX], 320
	MOV WORD [SCRNY], 200
	MOV DWORD [VRAM], 0x000a0000
	
	;; show keyboard LED status
	MOV ah, 0x02
	MOV 0x16
	MOV [LEDS], al
	
fin:
	HLT
	JMP fin
```

1. read data from disk onto memory
   + 0x8200 ~ 0x34fff
2. make os body, as horibote.sys
   + this is just a program
   + opening disk img and save this program as a file
   + search address with binary editor (lol)
3. run os img in boot sector
   + in this book, show VGA color
4. run in 32bit (after everything 16bit things done!)
5. go to 32bit mode and C code!
   + doing magic
