local ffi = require("ffi")
-- 使用するAPIの宣言を行う
ffi.cdef[[//C言語(C99)ソース文字列
//// 型宣言(typedef等)
typedef unsigned long DWORD;
//// プロトタイプ宣言
//現在プロセスのプロセスIDを取得
DWORD GetCurrentProcessId(void); //戻り値:プロセスID
]]

-------- 使用例
-- 宣言したAPI関数を呼び出す
local pid = ffi.C.GetCurrentProcessId()
-- pidにはプロセスIDの数値が返る
print("Process Id = "..tostring(pid))
-- EOF
