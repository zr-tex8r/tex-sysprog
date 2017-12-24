-- 文字コードはUTF-8
local ffi = require("ffi")
require("ffi_typedef")
ffi.cdef[[
//// プロトタイプ宣言
//短形式パス名を取得(Unicode版)
DWORD GetShortPathNameW(        //戻り値:出力パス名のサイズ,0=失敗
    LPCWSTR lpszLongPath,       //入力:長形式パス名
    LPWSTR lpszShortPath,       //出力:短形式パス名
    DWORD cchBuffer);           //出力:lpszShortPathのサイズ
//ANSIコードページを取得
UINT GetACP(void);              //戻り値:ANSIコードページ
//多バイト文字列をワイド文字列に変換
int MultiByteToWideChar(        //戻り値:変換後文字列の長さ,0=失敗
    UINT CodePage,              //入力:コードページ
    DWORD dwFlags,              //入力:文字種別フラグ
    LPCSTR lpMultiByteStr,      //入力:変換元文字列
    int cbMultiByte,            //入力:変換元文字列の長さ
    LPWSTR lpWideCharStr,       //出力:変換後文字列
    int cchWideChar);           //出力:lpWideCharStrのサイズ
//ワイド文字列を多バイト文字列に変換
int WideCharToMultiByte(        //戻り値:変換後文字列の長さ,0=失敗
    UINT CodePage,              //入力:コードページ
    DWORD dwFlags,              //入力:文字種別フラグ
    LPCWSTR lpWideCharStr,      //入力:変換元文字列
    int cchWideChar,            //入力:変換元文字列の長さ
    LPSTR lpMultiByteStr,       //出力:変換後文字列
    int cbMultiByte,            //出力:lpMultiByteStrのサイズ
    LPCSTR lpDefaultChar,       //入力:代替文字
    LPBOOL lpUsedDefaultChar);  // 出力:代替文字が使われたか
]]
Ccst = { -- 定数定義
    CP_UTF8 = 65001;            -- UTF-8のコードページ
}

--- 短形式パス名を取得.
-- @param lpath 長形式パス名
-- @return 短形式パス名(nil=失敗)
function short_path_name(lpath)
  if type(lpath) ~= "string" then return nil end
  if ffi.os ~= "Windows" then return lpath end
  -- UTF-8文字列→ワイド文字列
  local ulpath = ffi.new("WCHAR[?]", #lpath + 1)
  local ulplen = ffi.C.MultiByteToWideChar(Ccst.CP_UTF8, 0,
      lpath, #lpath + 1, ulpath, #lpath + 1)
  if ulplen == 0 then return nil end -- 失敗
  -- 長形式→短形式の変換
  local usplen = ffi.C.GetShortPathNameW(ulpath, nil, 0)
  if usplen == 0 then return nil end -- 失敗
  local uspath = ffi.new("WCHAR[?]", usplen + 1)
  usplen = ffi.C.GetShortPathNameW(ulpath, uspath, usplen + 1)
  if usplen == 0 then return nil end -- 失敗
  -- ワイド文字列→ANSI文字列
  local acp = ffi.C.GetACP()
  local spath = ffi.new("char[?]", usplen * 3)
  local dflt = ffi.new("BOOL[1]")
  local splen = ffi.C.WideCharToMultiByte(acp, 0,
      uspath, usplen, spath, usplen * 3, nil, dflt)
  if splen == 0 or dflt[0] ~= 0 then return nil end -- 失敗
  return ffi.string(spath, splen)
end

-------- 使用例
print(short_path_name("test file.txt"))
print(short_path_name("test ☆彡.txt"))
print(short_path_name("test ☃♪.txt"))

--- ファイルサイズの情報を表示する.
-- @param no 説明用の番号
-- @param path パス名
function show_file_size(no, path)
  local size = lfs.attributes(path, "size")
  print("("..no..") "..
      ((size) and "size = "..size or "not found"))
end

-- テスト
show_file_size("1", "test file.txt")
show_file_size("2", "test ☆彡.txt")
show_file_size("3", "test ☃♪.txt")
show_file_size("4", short_path_name("test file.txt"))
show_file_size("5", short_path_name("test ☆彡.txt"))
show_file_size("6", short_path_name("test ☃♪.txt"))
-- EOF
