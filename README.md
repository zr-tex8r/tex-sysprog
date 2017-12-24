TeXで覗くシステムプログラミングの世界（えっ）
==============================================

  * [TeXで覗くシステムプログラミングの世界（えっ）]（Qiita）

[TeXで覗くシステムプログラミングの世界（えっ）]: https://qiita.com/zr_tex8r/items/ea1e0511d58ee4b5bf6c

上記の記事で取り扱ったサンプルプログラムを置いています。

### 動作確認環境

  * LuaTeX 1.0.4版（TeX Live 2017収録）
  * Windows 10

### プログラム一覧

  * [hello.tex](./hello.tex)： システムダイアログを表示（LaTeX文書）
  * [ffi_typedef.lua](./ffi_typedef.lua)： Windows用のtypedefの一括登録（Luaモジュール）
  * [pid.lua](./pid.lua)： 現在プロセスのIDを表示
  * [sleep.lua](./sleep.lua)： 1秒ごとにカウントダウン表示
  * [shortname-1.lua](./shortname-1.lua)： ファイルのショートネームを取得
  * [console-1.lua](./console-1.lua)： UTF-8から端末出力コードページに変換
  * [console-2.lua](./console-2.lua)： UTF-8で与えた文字列を端末に出力
  * [shortname-2.lua](./shortname-2.lua)： ファイルのショートネームを取得（完全版）
  * [readlink.lua](./readlink.lua)： シンボリックリンクのリンク先を取得
  * [shutwindown.lua](./shutwindown.lua)： Windowsをシャットダウンする
  * [shutwindown.sty](./shutwindown.sty)： Windowsをシャットダウンする（LaTeXパッケージ）
  * [test-shutwindown.tex](./test-shutwindown.tex)： shutwindownのテスト（LaTeX文書）

--------------------
Takayuki YATO (aka. "ZR")  
https://github.com/zr-tex8r
