-- 文字コードはUTF-8
local ffi = require("ffi")
require("ffi_typedef")
ffi.cdef[[
//// 型宣言
typedef void *HANDLE;
//// プロトタイプ宣言
//端末出力コードページを取得
UINT GetConsoleOutputCP(void);  //戻り値:端末出力コードページ
//標準入出力のハンドルを取得
HANDLE GetStdHandle(            //戻り値:ハンドル
    DWORD nStdHandle);          //入力:取得対象
//コンソール入出力の現在のモードを取得
BOOL GetConsoleMode(            //戻り値:成功したか
    HANDLE hConsoleHandle,      //入力:コンソールのハンドル
    LPDWORD lpMode);            //出力:現在のモード
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
//コンソールに出力する(Unicode版)
BOOL WriteConsoleW(             //戻り値:成功したか
    HANDLE hConsoleOutput,      //入力:コンソールのハンドル
    const void *lpBuffer,       //入力:書き出す文字列
    DWORD nNumberOfCharsToWrite,//入力:文字列の長さ
    LPDWORD lpNumberOfCharsWritten,//出力:実際に書き出された文字数
    LPVOID lpReserved);
]]
Ccst = { -- 定数定義
    CP_UTF8 = 65001;            -- UTF-8のコードページ
    STD_OUTPUT_HANDLE = -11;    -- 標準出力(GetStdHandle用)
}

--- 文字列を端末に出力する
-- @param str UTF-8文字列
-- @return 成功したか
function cowrite(str)
  local istr, hso = tostring(str), nil
  -- 単純に出力してよいかを判定する
  -- OSがWindows以外, またはASCII文字列の場合は可能
  local simple = ffi.os ~= "Windows" or not istr:match("[\128-\255]")
  if not simple then
    -- 標準出力が端末であるかを判定する
    hso = ffi.C.GetStdHandle(Ccst.STD_OUTPUT_HANDLE)
    local ok = ffi.C.GetConsoleMode(hso, ffi.new("DWORD[1]"))
    -- GetConsoleModeが失敗なら端末でないと見なし, 単純出力を使う
    if ok == 0 then simple = true end
  end
  if simple then -- 単純出力を使う場合
    return (io.stdout:write(istr) ~= nil)
  end
  -- UTF-8文字列→ワイド文字列
  local ustr = ffi.new("WCHAR[?]", #istr)
  local ulen = ffi.C.MultiByteToWideChar(Ccst.CP_UTF8, 0,
      istr, #istr, ustr, #istr)
  if ulen == 0 then return false end -- 失敗
  -- ワイド文字列を出力する
  local olen = ffi.new("DWORD[1]")
  local ok = ffi.C.WriteConsoleW(hso, ustr, ulen, olen, nil)
  return (ok ~= 0) -- 成功したか
end

-------- 使用例
cowrite("TeXはアレ、☃は非アレ。\n")
-- EOF
