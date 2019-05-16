# 起動時の処理
BIOSが起動
まず最初にPOST(Power On Self Test)という処理が実行される

## Power On Self Test
その名の通り、自分自身のテストをする
メモリ、デバイスのチェック

## BIOS
ディスクからデータを読み書きできるようにするための読み込みや書き込みなどの処理と、処理を呼び出すテーブルを用意する
この読み込みを割り込み処理、処理を呼び出すテーブルを割込みベクタというらしい

割り込みベクタは、要は決まった処理をする関数を登録するテーブルに過ぎない
この割り込みベクタと処理はBIOSが用意する
この処理をブートローダが利用する

## 割り込み処理の次は
ブートローダをメモリに読み込む
ブートローダはディスクの決められた位置に格納する決まりになっている
最初のセクタに格納されているはずで、ブートに使われるのでブートセクタという
フロッピーディスクなら1つのセクタが512バイトなので、最初の512バイトを読み込む
CD-ROMなら1つのセクタは2048バイトなので、最初の2048バイトを読み込む

## セクタ
ディスクが扱うブロック => SSDではどうなってるんだろ
読み込みの単位

## 最初のセクタを読み込む
### フロッピーの読み込み処理
アセンブラのINT命令でフロッピーの読み込み処理ができる
INT命令を実行すると、割り込みベクタから割り込み処理のアドレスを読み込んでジャンプし、命令を実行する
割り込みベクタのどこにどの処理が入っているかは決められている
25番目(0x19)はフロッピーの読み込み処理

TODO: check
### 0x19
フロッピーの読み込み処理とあるが、単なる読み込みではなくCDやHDDの読み込みもする 
=> セットアップなのか？
=> Bootstrap Routineなのでブートストラップ処理
とりあえずブートディスクの最初のセクタを読み込んでメモリに配置する
読み込んだ512バイト(フロッピーの場合)の511、512が0x55, 0xaaだとメモリの0x7c00番地に最初のセクターがコピーされる => どんな計算でそのオフセットなんだ?
そして0x7c00にブートローダーがコピーされるとそこから処理を開始する

## FAT12
容量の少ないディスクで使われるファイルシステム
BPB(BIOS Parameter Block)というものがあり、ディスクのセクタ数などを記録する

### FAT12のブートセクタ
ファイルシステムごとに規定がある？
最初の数バイトを指定されたフィールドとして埋めていく必要がある
=> あとでFAT32とかのも調べてみようか？

### セグメント
セグメントの開始位置=セグメントレジスタの値 * 0x10

### セグメントレジスタの種類
CS コードセグメント: プログラムの命令が置いてある場所を指定する
DS, ES, FS, GS データセグメント: データの場所を指定する
SS スタックセグメント: スタック

命令中のアクセスで使われるアドレスは全部これらのレジスタを元に決定される

ES, FS, GSではアクセスするときどれをベースにするか選ぶ引つよう がある
アドレスの書き方が[ES:BX]のようになる
これを論理アドレスという
実際のアドレスをリニアアドレスという

スタックは大きいアドレスから使う

### 文字表示
int 0x10 ; => Video Services
ah,al,bh,blを引数として受け取る
場合によっては他のも

ah=0x13番
```asm
	mov	ah, 0x13	; write string
	mov	al, 0x01	; only write string, cursor is moved
	mov	bh, 0x00	; 0x00
	mov	bl, 0x1f	; color code, called attribute
	mov	cx, 0x0d	; length of string
	mov	dl, 0x03	; x
	mov	dh, 0x03	; y
	mov	bp, Hello	; string addr
	int	0x10		; call BIOS interupt vector
	
	HLT			; CPUを停止させる命令

Hello	db "HELLO, WORLD!",0x00	; C言語にならってヌル終端
```

## フロッピーからデータを読み込む
int 0x13, disk services
2つのモードがある
初期化モード、セクタ読み込みモード

初期化モード
ヘッドを最初のセクタに戻せる
ah=0x00, 初期化モード
dl=0x00, リセットするドライブ番号
返り値
ah=status code
成功 CF=0, 失敗CF=1

セクタ読み込みモード
ah=0x02, セクタ読み込みモード
al=読み込むセクタの数
ch=シリンダ番号の16ビットの下位1バイト
cl=読み込むセクタの番号。ハードディスクだと下位0-5bitの0x01-0x24(1-36)の範囲でセクタを指定、上位2bitでシリンダ番号を指定
dh=ヘッド番号
dl=ドライブ番号
es:bx=読み込んだデータを格納するアドレス

フロッピー
セクタ: 512バイト
シリンダ: 18セクタ、1~18
ヘッド: 2つ、0~1、80シリンダ

### Logical Block Addressing(LBA)
LBAではメモリのアドレスをバイト単位ではなくセクタ単位で扱う。
全セクタに番号付けすることで、面倒なシリンダの管理を避ける。

`LBA = head * cyn_num * sec_num + cyn * sec_num + sec`
head: ヘッダ番号
cyn: シリンダ番号
sec: セクタ番号

__fix__
qemu, hddで試すと正しくなかった
1セクターごとにヘッダ順にデータが並ぶ、連続で読み込む場合は1セクター分の動きで連続したセクターが読める

```
LBA = cyn * head_num * sec_num + head * sec_num + sec
head_num: シリンダごとのヘッダ数
sec_num: ヘッダごとのセクター数
```

```
;;;
;;; LBA2CHS
;;; input AX:sector number(LBA)
;;; output AX:quotient, DX:Remainder
;;; convert physical address to logical address
;;; physical sector = (logical sector MOD sectors per track) + 1
;;; physical head   = (logical sector / sectors per track) MOD number of heads
;;; physical track  = logical sector / (sectors per track * number of heads)
LBA2CHS:
	push	ax
	push	dx
	xor	dx, dx
	div	word [BPB_SecPerTrk] ; ax <= ax / arg, dx <= ax % arg
	inc	dl
	mov	byte [physicalSector], dl
	xor	dx, dx
	div	word [BPB_NumHeads]
	mov	byte [physicalHead], dl
	mov	byte [physicalTrack], al
	pop	dx
	pop	ax
	ret
;;; for LBA2CHS and LBA2CHS4HD
physicalSector	db	0x00
physicalHead	db	0x00
physicalTrack	dw	0x0000

;;; Read Sector from drive
;;; args
;;; ax: sector number
;;; bx: address to read sectors
;;; es: base address to read sectors
;;; cl: the number of sector to read
ReadSectors:
	pusha
	
	call	LBA2CHS
	mov	ah, 0x02		; read sector mode
	mov	al, cl		; num of sector to read
	mov	cl, [physicalSector]	; sector number
	mov	ch, [physicalTrack]		; under 1 byte of track number	
	mov	dh, [physicalHead]		; header num
	mov	dl, 0x00				; drive num
	xor	dl,	HardDiskFlag
	
	int	0x13
	;; error check
	jc	ReadSecErr
	popa
	ret
ReadSecErr:
	mov	si, ReadSecErrMsg
	call	DisplayMessage
	hlt
ReadSecErrMsg	db	"ReadSectorsError",0x00
	ret
```

### FAT12 FS
次の領域に分かれている
+ ブートセクタ
  - ブートローダが入る
+ FAT領域
  - File Allocation Table
+ ルートディレクトリ領域
  - ルートディレクトリの情報、そのまま
+ ファイル領域
  - 実際のデータが格納されていく領域
  

### ルートディレクトリ
ファイルの情報がエントリとして格納されている

# memo
とりあえず最初は必要なフィールドを配置してディスクからファイルを読み込めるようにすればいいらしい

# 画面モード
ビデオBIOS
AH=0x00
AL=モード

+ モード
  - 0x03: 16色テキスト, 80x25
  - 0x12: VGA, 640x480x4bit、独自プレーンアクセス
  - 0x13: VGA, 320x200x8bit、バックドピクセル
	- 0x6a: 拡張VGA, 800x600x4bit, 独自プレーンアクセス
