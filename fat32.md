[http://www.geocities.co.jp/SiliconValley-PaloAlto/2038/fat.html]
[http://elm-chan.org/docs/fat.html#bpb]

最初はブートセクタのためのフィールドがあり、その次にBIOSのためのフィールドがある
その直後にブートセクタのためのフィールドがある

ファイルシステムの情報が存在しているクラスタ番号は`BPB_FSInfo`フィールドで指定される。
常に1、ここにFAT32のFSInfo構造体の情報を格納していく。
これは空きクラスタの検索の効率化などのために使われる構造体になる。
