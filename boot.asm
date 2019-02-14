;;; ブートローダー
	[BITS 16] 		; 互換性のため、16ビットモードに指定する。通称リアルモード

	ORG	0x7c00		; このプログラムが0x7c00で始まることを宣言している。アドレスを指定するときのbpになる

;;; BIOS Parameter Blocks for FAT12
JMP	BOOT
BS_jmpBoot2	DB	0x90
BS_OEMName	DB	"MyOS    "
BPB_BytsPerSec	DW	0x0200		;BytesPerSector
BPB_SecPerClus	DB	0x01		;SectorPerCluster
BPB_RsvdSecCnt	DW	0x0001		;ReservedSectors
BPB_NumFATs	DB	0x02		;TotalFATs
BPB_RootEntCnt	DW	0x00E0		;MaxRootEntries
BPB_TotSec16	DW	0x0B40		;TotalSectors
BPB_Media	DB	0xF0		;MediaDescriptor
BPB_FATSz16	DW	0x0009		;SectorsPerFAT
BPB_SecPerTrk	DW	0x0012		;SectorsPerTrack
BPB_NumHeads	DW	0x0002		;NumHeads
BPB_HiddSec	DD	0x00000000	;HiddenSector
BPB_TotSec32	DD	0x00000000	;TotalSectors
BS_DrvNum	DB	0x00		;DriveNumber
BS_Reserved1	DB	0x00		;Reserved
BS_BootSig	DB	0x29		;BootSignature
BS_VolID	DD	0xffffffff	;VolumeSerialNumber 日付を入れました
BS_VolLab	DB	"MyOS       "	;VolumeLabel
BS_FilSysType	DB	"FAT12   "	;FileSystemType
	
BOOT:
	CLI			; 割り込みを受け付けないようにフラグをクリアする命令、意味はない

	;; initialize
	xor	ax, ax
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax

	xor	bx, bx
	xor	cx, cx
	xor	dx, dx

	mov	ss, ax
	mov	sp, 0xfffc

	mov	si, Hello
	call	DisplayMessage

	mov	ax, 2000
	call	ReadSectors
	
	HLT			; CPUを停止させる命令


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Load Root From Floppy
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
LOAD_ROOT:
	MOV	BX, WORD [BX_RTDIR_ADDR]
	XOR	CX, CX
	MOV	WORD [datasector], AX		; FATを読み込んだ直後なので、
						; AXにはルートディレクトリの開始が入っています
	XCHG	AX, CX

	MOV	AX, 0x0020		
	MUL	WORD [BPB_RootEntCnt]
	ADD	AX,  WORD[ BPB_BytsPerSec ]
	DEC	AX	
	DIV	WORD [BPB_BytsPerSec]
	XCHG	AX, CX						
	ADD	WORD [datasector], CX		; CXにはルートディレクトリのサイズ（セクタ数）が入っていますので
						; 足します


	MOV	AX, WORD [BX+0x001A]		; ルートディレクトリのエントリから
						; ファイルの開始クラスタ番号を取得
	MOV	BX, WORD[ES_IMAGE_ADDR]		; ファイルを格納する先のデータセグメントを
						; BXに入れる
	MOV	ES, BX				; ESにBXの値を格納する（ESセグメントに格納する）
	XOR	BX, BX	 			; BXを初期化（ESセグメントのオフセット）
	PUSH	BX				; ファイルを格納する先のオフセットをスタックに退避
	MOV	WORD [cluster], AX		; ファイルの開始クラスタ番号をclusterに入れる
	
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Browse Root directory
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
	MOV	BX, WORD [BX_RTDIR_ADDR]	; 読み込んだルートディレクトリのアドレスを取得します
	MOV	CX, WORD [BPB_RootEntCnt]	; エントリの数を取得します
	MOV	SI, ImageName			; 読み込みたいファイル名のアドレスを取得します（11文字）
BROWSE_ROOT:					; ルートディレクトリ探索開始
	MOV	DI, BX				; ルートディレクトリのエントリのアドレスをDIに格納
	PUSH	CX				; CX（エントリ数）を退避
	MOV	CX, 0x000B			; CXに0x00B（11文字）を格納
	PUSH	DI				; DIを退避
	PUSH	SI				; SIを退避
REPE	CMPSB					; 文字列CMPSB命令を繰り返す
						; REPEはCXに格納されている値（11文字）分CMPSB命令を繰り返します
						; CMPSB命令はDS:SIに格納されている1バイトと
						; ES:DIに格納されている1バイトを比較します
						; 比較結果は一致しなかったバイト数がCXに格納されます
	POP	SI				; SIを元の値に戻します
	POP	DI				; DIを元の値に戻します
	JCXZ	BROWSE_FINISHED			; CXが0であればFinishへ（Jamp if CX is Zero)
	ADD	BX, 0x0020			; 次のエントリを見に行くため32バイト足します
	POP	CX				; CXを元の値に戻します

	LOOP	BROWSE_ROOT			; 次のエントリを見に行きます。BROWSE_ROOTにジャンプ
						; LOOP命令はCXの値（エントリの数）分ループします
	JMP	FAILURE				; エントリを全部見終わってファイルが無ければ失敗

BROWSE_FINISHED:				; ファイル発見
	POP	CX				; CXの値を元に戻します（PUSHしたままなのでSPを元にもどす）
	mov	ax, word [bx + 0x001a]				

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Load Image 
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
LOAD_IMAGE:
	MOV	AX, WORD [cluster]		; clusterに入っているクラスタ番号をAXに入れる
	POP	BX				; ファイルを格納する先のオフセットを元に戻す
	CALL	ClusterLBA			; ファイルの先頭セクタ番号を計算する
	XOR	CX, CX						
	MOV	CL, BYTE [BPB_SecPerClus]	; 1クラスタあたりのセクタ数をCLに入れる
	CALL	ReadSector			; ファイルクの一部（1セクタ）をES:BXに読み込む
	ADD	BX, 0x0200			; 1セクタ読み込んだので1セクタ（0x200バイト）分
						; オフセットを進める
	PUSH	BX				; BXの内容が変更されるので退避
; ここから次のクラスタを調べる
	MOV	AX, WORD [cluster]		; AXの値は変更されてしまったので、再度clusterを入れる
	MOV	CX, AX				; CXに調べるクラスタ番号を入れる		
	MOV	DX, AX				; DXに調べるクラスタ番号を入れる
	SHR	DX, 0x0001			; クラスタ番号N / 2
	ADD	CX, DX				; クラスタのオフセットを計算
	MOV	BX, WORD[BX_FAT_ADDR]		; 読み込んだFAT領域のアドレスをBXに入れます
	ADD	BX, CX				; 調べたいクラスタのアドレスを計算
	MOV	DX, WORD [BX]			; DXにクラスタNの値を入れる
	TEST	AX, 0x0001			; 奇数か、偶数かを調べる
	JNZ	ODD_CLUSTER			; ZFが0でない場合ODD_CLUSTERへ
EVEN_CLUSTER:					; 偶数クラスタの処理
	AND	DX, 0x0FFF			; 次クラスタの値を取得（DX）
	JMP	LOCAL_DONE			; 次クラスタ読み込み完了
ODD_CLUSTER:					; 奇数クラスタの処理
	SHR	DX, 0x0004			; 次クラスタの値を取得（DX）
LOCAL_DONE:					; 次クラスタ読み込み完了処理
	MOV	WORD [cluster], DX		; 次クラスタ番号をclusterへ
	CMP	DX, 0x0FF0			; 終端クラスタか調べる
	JB	LOAD_IMAGE			;　終端クラスタでない場合はLOAD_IMAGEへ戻る
		
ALL_DONE:					; ファイル読み込み完了
	POP	BX				; スタックポインタを戻すため、意味は無いがBXの値を元に戻す
	MOV	SI, msgIMAGEOK			; 成功メッセージを表示
	call 	DisplayMessage	

	HLT					; 停止
	
	
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
; PROCEDURE ClusterLBA
; convert FAT cluster into LBA addressing scheme
; LAB = (cluster - 2 ) * sectors per cluster
; INPUT  : AX : cluster number
; OUTPUT : AX : base image sector
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
ClusterLBA:
	SUB	AX, 0x0002			
	XOR	CX, CX
	MOV	CL, BYTE [BPB_SecPerClus]
	MUL	CX
	ADD	AX, WORD [datasector]		; ここでdatasectorはファイル領域の開始セクタ番号
						; そこにクラスタ番号から計算したオフセットを足せば
						; 読み込みたいファイルのセクタ番号を取得できる
	RET
	
	hlt

Hello	db 	"HELLO, WORLD!",0x00	; C言語にならってヌル終端
cluster	dw	0x0000
	
DisplayMessage:
	PUSH	AX
	PUSH	BX
StartDispMsg:
	LODSB			; al <= ds:si, si++
	OR	AL, AL
	JZ	.DONE
	MOV	AH, 0x0E
	MOV	BH, 0x00
	MOV	BL, 0x07
	INT	0x10
	JMP	StartDispMsg
.DONE:
	POP	BX
	POP	AX
	RET

ResetFloppyDrive:
	mov	ah, 0x00
	mov	dl, 0x00
	int	0x13
	jc	FAILURE
	HLT
FAILURE:
	HLT

ReadSectors:
	call	LBA2CHS
	mov	ah, 0x02
	mov	al, 0x01
	mov	ch, byte [physicalTrack]
	mov	cl, byte [physicalSector]
	mov	dh, byte [physicalHead]
	mov	dl, byte [BS_DrvNum]
	mov	bx, 0x1000
	mov	es, bx
	mov	bx, 0x0000
	int	0x13
	ret

Load_FAT:
	mov	bx, word [BX_FAT_ADDR] ; bx <= Fatを読み込むアドレス
	add	ax, word [BPB_RsvdSecCnt]
	xchg	ax, cx		; Fatの開始アドレスをcxに
	mov	ax, word [BPB_FATSz16]
	mul	word [BPB_NumFATs] ; Fatのサイズを取得
	xchg	ax, cx
READ_FAT:
	call	ReadSector
	add	bx, word [BPB_BytsPerSec]
	inc	ax
	dec	cx
	jcxz	FAT_LOADED
	jmp	READ_FAT
FAT_LOADED:
	HLT


;;; 
; ReadSector
; Read 1 Sector 
; Input: BX:読み込んだセクタを格納するアドレスを入れておく  
;      : AX:読み込みたいLBAのセクタ番号
ReadSector:
	MOV	DI, 0x0005			; エラー発生時5回までリトライする
SECTORLOOP:
	PUSH	AX				; AX、BX、CXをスタックに退避
	PUSH	BX
	PUSH	CX
	CALL	LBA2CHS				; AXのLBAを物理番号に変換
	MOV	AH, 0x02			; セクタ読み込みモード
	MOV	AL, 0x01			; 1セクタ読み込み
	MOV	CH, BYTE [physicalTrack]	; LBA2CHSで計算したトラック番号
	MOV	CL, BYTE [physicalSector]	; LBA2CHSで計算したセクタ番号
	MOV	DH, BYTE [physicalHead]		; LBA2CHSで計算したヘッド番号
	MOV	DL, BYTE [BS_DrvNum]		; ドライブ番号（Aドライブ）
	INT	0x13				; BIOS処理呼び出し
	JNC	SUCCESS				; CFを見て成功か失敗かを判断
	XOR	AX, AX				; ここからエラー発生時の処理。ドライブ初期化モード
	INT	0x13				; エラーが発生した時はヘッドを元に戻す
	DEC	DI				; エラーカウンタを減らす
	POP	CX				; AX、BX、CXの値が変更されたので
	POP	BX				; 退避したいたデータをスタックから元に戻す
	POP	AX
	JNZ	SECTORLOOP			; DEC　DIの計算結果が0でなければ、セクタ読み込みをリトライ
	INT	0x18				; 昔のソースなので何がしたかったのか？？？Set Media Type
SUCCESS:
	POP	CX				; 成功時の処理レジスタの値を元に戻す
	POP	BX
	POP	AX
	RET	

BX_FAT_ADDR		DW 0x7E00		; データセグメントの0x7E00にFATを読み込む
	
;;; 
;;; LBA2CHS
;;; input AX:sector number(LBA)
;;; output AX:quotient, DX:Remainder
;;; convert physical address to logical address
;;; physical sector = (logical sector MOD sectors per track) + 1
;;; physical head   = (logical sector / sectors per track) MOD number of heads
;;; physical track  = logical sector / (sectors per track * number of heads)
LBA2CHS:
	xor	dx, dx
	div	word [BPB_SecPerTrk] ; ax <= ax / arg, dx <= ax % arg
	inc	dl
	mov	byte [physicalSector], dl
	xor	dx, dx
	div	word [BPB_NumHeads]
	mov	byte [physicalHead], dl
	mov	byte [physicalTrack], al
	ret

physicalSector	db	0x00
physicalHead	db	0x00
physicalTrack	db	0x00	
	
	;; プリプロセッサで処理される疑似命令。DBはデータを直接配置する命令で、D=Define, B=Byteの意味
	;; この位置に1バイト分0を配置することになる
	;; $は現在のアドレス、$$は最初の命令(CLI)のアドレス
	;; TIMESは指定された数だけ命令を繰り返す
	;; つまり、510バイトになるように0で埋めているだけ
	TIMES 510 - ($ - $$) DB 0
	;; 最後にDW(W=Word)で0xaa55を配置する。コピーされるセクタの指定っぽい
	;; 16ビットモードなのでWordは16ビット
	DW	0xaa55
