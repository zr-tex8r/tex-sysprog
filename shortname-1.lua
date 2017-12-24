local ffi = require("ffi")
ffi.cdef[[
//// 型宣言
typedef unsigned long DWORD;
typedef const char *LPCSTR;
typedef char *LPSTR;
//// プロトタイプ宣言
//短形式パス名を取得
DWORD GetShortPathNameA(        //戻り値:出力パス名のサイズ,0=失敗
    LPCSTR lpszLongPath,        //入力:長形式パス名
    LPSTR lpszShortPath,        //出力:短形式パス名
    DWORD cchBuffer);           //出力:lpszShortPathのサイズ
]]

--- 短形式パス名を取得.
-- @param lpath 長形式パス名
-- @return 短形式パス名
function short_path_name(lpath)
  local spath = ffi.new("char[?]", 512)
  local splen = ffi.C.GetShortPathNameA(lpath, spath, 512)
  if splen == 0 then return nil end -- 失敗
  return ffi.string(spath, splen)
end

-------- 使用例
print(short_path_name("test file.txt"))

-- これはダメ！
-- print(short_path_name("test ☆彡.txt"))
-- print(short_path_name("test ☃♪.txt"))
-- EOF
