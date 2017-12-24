-- 文字コードはUTF-8
local ffi = require("ffi")
require("ffi_typedef")
ffi.cdef[[
//// プロトタイプ宣言
//端末出力コードページを取得
UINT GetConsoleOutputCP(void);  //戻り値:端末出力コードページ
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

--- 文字列を端末出力コードページに変換
-- @param str UTF-8文字列
-- @return 端末出力CP文字列(nil=失敗)
function costr(str)
  local istr = tostring(str)
  if #istr == 0 or ffi.os ~= "Windows" then return istr end
  -- UTF-8文字列→ワイド文字列
  local ustr = ffi.new("WCHAR[?]", #istr)
  local ulen = ffi.C.MultiByteToWideChar(Ccst.CP_UTF8, 0,
      istr, #istr, ustr, #istr)
  if ulen == 0 then return nil end -- 失敗
  -- ワイド文字列→端末出力文字列
  local cocp = ffi.C.GetConsoleOutputCP()
  local ostr = ffi.new("char[?]", #istr)
  local olen = ffi.C.WideCharToMultiByte(cocp, 0,
      ustr, ulen, ostr, #istr, nil, nil)
  if ulen == 0 then return nil end -- 失敗
  return ffi.string(ostr, olen)
end

-------- 使用例
print(costr("TeX言語危険、ダメゼッタイ！"))
-- EOF
