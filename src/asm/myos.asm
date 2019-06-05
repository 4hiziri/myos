;;; BOOT_INFO
BOTPAK	EQU		0x00280000		; addr to load bootpack
DSKCAC	EQU		0x00100000		; addr of disk cache
DSKCAC0	EQU		0x00008000		; addr of real mode disk cache
	
CYLS	EQU 0x0ff0				; set by boot sector
LEDS	EQU 0x0ff1
VMODE	EQU	0x0ff2
SCRNX	EQU 0x0ff4
SCRNY	EQU	0x0ff6
VRAM	EQU	0x0ff8

	ORG	0x8200
	
	;; Change screen mode
	mov	al, 0x13				; VGA Graphics, 320x200x8bit
	mov	ah, 0x00
	int	0x10

	mov byte [VMODE], 0x08		; save screen mode
	mov word [SCRNX], 320
	mov word [SCRNY], 200
	mov dword [VRAM], 0x000a0000

	;; check keyboard status
	mov ah, 0x02
	int 0x16					; keyboard BIOS
	mov [LEDS], al

	;; make PIC not accept interrupt
	;; According to the specification of AT compatible machine, PIC should be initialized before CLI.
	;; PIC will initialized after

	mov al, 0xff
	out 0x21, al
	nop		 					; some chip cannot do serial out
	out 0xa1, al

	cli							; block interrupt by CPU

	;; configure A20GATE for memory access over 1MB
	call waitkbdout
	mov al, 0xd1
	out 0x64, al
	call waitkbdout
	mov al, 0xdf				; enable A20
	out 0x60, al
	call waitkbdout

	;; Change to Protect Mode
	lgdt [GDTR0]				; configure temporary GDT
	mov eax, cr0
	and eax, 0x7fffffff	   ; bit31 = 0, inhibit paging
	or eax,	0x00000001	; bit0 = 1, change protect mode
	mov cr0, eax
	jmp pipelineflush
pipelineflush:
	mov		ax, 1*8			;  読み書き可能セグメント32bit
	mov		ds, ax
	mov		es, ax
	mov		fs, ax
	mov		gs, ax
	mov		ss, ax

	;; transport bootpack
	
	mov esi, bootpack	; 転送元
	mov edi, BOTPAK		; 転送先
	mov ecx, 512*1024/4
	call memcpy
	
	;; transport disk data
	;; boot sector
	mov esi, 0x7c00			; src
	mov edi, DSKCAC			; dest
	mov ecx, 512/4
	call memcpy

	;; rest

	mov esi, DSKCAC0+512	; 転送元
	mov edi, DSKCAC+512	; 転送先
	mov ecx, 0
	mov cl, byte [CYLS]
	imul ecx, 512*18*2/4	; シリンダ数からバイト数/4に変換
	sub ecx, 512/4		; IPLの分だけ差し引く
	call memcpy

	;; launch bootpack

	mov ebx, BOTPAK
	mov ecx, [ebx+16]
	add ecx, 3			; ECX += 3;
	shr ecx, 2			; ECX /= 4;
	jz skip
	mov esi, [ebx+20]
	add esi, ebx
	mov edi, [ebx+12]
	call memcpy
skip:
	mov esp, [ebx+12]	; stack init val
	jmp dword 2*8:0x0000001b
	;; mov esp, 0x00310000
	;; jmp dword 2*8:0x00000000

waitkbdout:
	in al, 0x64
	and al, 0x02
	jnz waitkbdout
	ret

memcpy:
	mov eax, [esi]
	add esi, 4
	mov [edi], eax
	add edi, 4
	sub ecx, 1
	jnz memcpy
	ret
	;; memcpyはアドレスサイズプリフィクスを入れ忘れなければ、ストリング命令でも書ける

	alignb 16
GDT0:
	resb	8	; null selector
	RWSEG dw 0xffff,0x0000,0x9200,0x00cf	; read-write seg, 32bit
	EXECSEG dw 0xffff,0x0000,0x9a28,0x0047	; exec seg, 32bit for bootpack

	dw		0
GDTR0:
	dw		8*3-1
	dd		GDT0

	alignb 16
bootpack:
