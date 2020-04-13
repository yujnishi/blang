# b言語コンパイラ

## コンパイル
まず必要なソフトウェアのインストール(ほかに必要なものがあったら適宜インストールしてください)
```
sudo yum install flex bison llvm
```
コンパイル
```
gmake
``` 

## インストール
```
gmake install
```

## アンインストール
```
gmake uninstall
```

## 使い方
```
blang source.b
```
結果は `a.out` というファイル名で出ます

## 言語仕様について
[wikipedia](https://ja.wikipedia.org/wiki/B%E8%A8%80%E8%AA%9E)、参考文献を参考(とくに[Users' Reference to B](https://web.archive.org/web/20150317033259/https://www.bell-labs.com/usr/dmr/www/kbman.pdf)を参照)に同じような動きになるよう作ってみました。

testsディレクトリの下に実際にコンパイルして動作確認しているものをおいているので参考にしてください。


