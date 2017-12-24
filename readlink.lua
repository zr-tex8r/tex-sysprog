local ffi = require("ffi")
require("ffi_typedef")
ffi.cdef[[
//// 型宣言
typedef void *HANDLE;
typedef struct {                        //再解析ポイント情報
    ULONG  ReparseTag;
    USHORT ReparseDataLength;
    USHORT Reserved;
    //※VLSとして扱いたいので、不要な共用体要素を省く
    USHORT SubstituteNameOffset;
    USHORT SubstituteNameLength;
    USHORT PrintNameOffset;
    USHORT PrintNameLength;
    ULONG  Flags;
    //可変長配列(VLA)の要素
    WCHAR  PathBuffer[?];
} REPARSE_DATA_BUFFER, *PREPARSE_DATA_BUFFER;
//※以下はダミー定義
typedef void *LPSECURITY_ATTRIBUTES;
typedef void *LPOVERLAPPED;
//// プロトタイプ宣言
//ファイル・ディレクトリの属性を取得する
DWORD GetFileAttributesW(       //戻り値:ファイルの属性
    LPCWSTR lpFileName);        //入力:ファイルパス名
//ファイルを開いてハンドルを作成する
HANDLE CreateFileW(             //戻り値:ファイルハンドル
    LPCWSTR lpFileName,         //入力:ファイルパス名
    DWORD dwDesiredAccess,      //入力:アクセスモード
    DWORD dwShareMode,          //入力:共有モード
    LPSECURITY_ATTRIBUTES lpSecurityAttributes, //入力:セキュリティ記述子
    DWORD dwCreationDisposition, //入力:ファイル作成の指定
    DWORD dwFlagsAndAttributes, //入力:ファイル作成時の属性
    HANDLE hTemplateFile);      //入力:テンプレートファイルハンドル
//デバイスの直接入出力制御
BOOL DeviceIoControl(          //戻り値:成功したか
    HANDLE hDevice,            //入力:デバイスハンドル
    DWORD dwIoControlCode,     //入力:制御コード
    LPVOID lpInBuffer,         //入力:入力データ
    DWORD nInBufferSize,       //入力:lpInBufferのサイズ
    LPVOID lpOutBuffer,        //出力:出力データのバッファ
    DWORD nOutBufferSize,      //入力:lpOutBufferのサイズ
    LPDWORD lpBytesReturned,   //出力:実際の出力データのサイズ
    LPOVERLAPPED lpOverlapped); //入力:非同期動作の指定
//オブジェクトハンドルを閉じる
BOOL CloseHandle(              //戻り値:成功したか
    HANDLE hObject);           //入力:オブジェクトハンドル
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
  CP_UTF8 = 65001;
  FILE_ATTRIBUTE_REPARSE_POINT = 0x00000400;
  GENERIC_READ = 0x80000000;
  FILE_SHARE_READ = 0x00000001;
  FILE_SHARE_WRITE = 0x00000002;
  FILE_SHARE_DELETE = 0x00000004;
  OPEN_EXISTING = 3;
  FILE_FLAG_BACKUP_SEMANTICS = 0x2000000;
  FILE_FLAG_OPEN_REPARSE_POINT = 0x200000;
  INVALID_HANDLE_VALUE = ffi.cast("HANDLE", -1);
  FSCTL_GET_REPARSE_POINT = 0x900A8;
  IO_REPARSE_TAG_SYMLINK = 0xA000000C;
}

-- cf. http://www.wabiapp.com/WabiSampleSource/windows/get_reparse_point.html

--- シンボリックリンクの参照先を取得する
-- @param path シンボリックリンクのパス名
-- @returns 参照先のパス名(nil=失敗)
function readlink(path)
  if type(path) ~= "string" then return nil end
  if ffi.os ~= "Windows" then return lfs.readlink(path) end
  -- UTF-8文字列→ワイド文字列
  local upath = ffi.new("WCHAR[?]", #path + 1)
  local uplen = ffi.C.MultiByteToWideChar(Ccst.CP_UTF8, 0,
      path, #path + 1, upath, #path + 1)
  if uplen == 0 then return nil end -- 失敗
  -- ファイルの属性を調べる
  local fatr = ffi.C.GetFileAttributesW(upath)
  if fatr == -1 or -- APIが失敗
     -- ファイルが再解析ポイントでない
     not bit32.btest(fatr, Ccst.FILE_ATTRIBUTE_REPARSE_POINT) then
    return nil -- 失敗
  end

  local ret, hfile
  repeat -- break可能なブロック
    -- ファイルハンドル取得
    hfile = ffi.C.CreateFileW(upath, Ccst.GENERIC_READ,
        Ccst.FILE_SHARE_READ + Ccst.FILE_SHARE_WRITE + Ccst.FILE_SHARE_DELETE,
        nil, Ccst.OPEN_EXISTING,
        Ccst.FILE_FLAG_BACKUP_SEMANTICS + Ccst.FILE_FLAG_OPEN_REPARSE_POINT,
        nil)
    if hfile == Ccst.INVALID_HANDLE_VALUE then break end -- 失敗
    -- 再解析ポイントの情報を取得
    local uoplen = 32768
    local rdata = ffi.new("REPARSE_DATA_BUFFER", uoplen)
    local rdlen = ffi.new("DWORD[1]")
    local ok = ffi.C.DeviceIoControl(hfile, Ccst.FSCTL_GET_REPARSE_POINT,
        nil, 0, rdata, ffi.sizeof(rdata), rdlen, nil)
    if ok == 0 then break end -- 失敗
    local rtag = bit32.bor(rdata.ReparseTag)
        -- 再解析ポイントがシンボリックリンクではない
    if rtag ~= Ccst.IO_REPARSE_TAG_SYMLINK then break end -- 失敗
        -- SubstituteName～ はバイト単位なので文字単位の値を得る
    local sso = rdata.SubstituteNameOffset / 2 -- オフセット
    local ssl = rdata.SubstituteNameLength / 2 -- 文字数
        -- 文字数が整数でない
    if sso % 1 ~= 0 or ssl % 1 ~= 0 then break end -- 失敗
    local uopath = rdata.PathBuffer + sso --※ポインタ演算
    -- ワイド文字列→ANSI文字列
    local opath = ffi.new("char[?]", ssl * 4 + 1)
    local oplen = ffi.C.WideCharToMultiByte(Ccst.CP_UTF8, 0,
      uopath, ssl, opath, ssl * 4, nil, nil)
    if oplen == 0 then break end -- 失敗
    ret = ffi.string(opath, oplen)
  until true

  -- ファイルハンドルを閉じる
  if hfile ~= nil then
    ffi.C.CloseHandle(hfile)
  end

  return ret
end

-------- 使用例
print("symlink.txt links to: "..readlink("symlink.txt"));
-- EOF
