OUTPUT_FORMAT("binary");
IPLBASE = 0x7c00;
 
SECTIONS {
    . = IPLBASE;
    .text   : {*(.text)}
    .data   : {*(.data)}
    . = IPLBASE + 510;
	.sgin	: {FILL(0xaa55)}
	.sign	: {FILL(0x41615252)}
	. = IPLBASE + 510 + 6 + 480;
	sign	: {FILL(0x61417272)}
	sign	: {FILL(0x0007fdfd)}
	sign	: {FILL(0x00000002)}
	. = IPLBASE + 510 + 6 + 480 + 12 + 12;
	sign	: {FILL(0xaa55)}
}
