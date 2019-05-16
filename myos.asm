ORG	0x40e000
	
	;; Change screen mode
	mov	al, 0x13				; VGA Graphics, 320x200x8bit
	mov	ah, 0x00
	int	0x10
	
fin:
	hlt
	jmp	fin
