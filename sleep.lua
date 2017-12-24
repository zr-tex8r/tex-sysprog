local ffi = require("ffi")
ffi.cdef[[
//// 型宣言(typedef等)
typedef unsigned long DWORD;
//// プロトタイプ宣言
//指定時間だけプロセス実行を中断
void Sleep(
    DWORD dwMilliseconds);      //入力:待機時間(ミリ秒)
]]

-------- 使用例
for count = 5, 1, -1 do
  print(count)
  ffi.C.Sleep(1000) -- 1秒待つ
end
print("Finish!")
-- EOF
