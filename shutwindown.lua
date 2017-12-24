local ffi = require("ffi")
require("ffi_typedef")
ffi.cdef[[
//// 型宣言
typedef void *HANDLE;
typedef HANDLE *PHANDLE;
typedef struct {                //ローカル一意識別子
    DWORD LowPart;
    LONG HighPart;
} LUID, *PLUID;
#pragma pack(4)
typedef struct {                //LUIDとその属性
    LUID Luid;
    DWORD Attributes;
} LUID_AND_ATTRIBUTES;
#pragma pack(8)
typedef struct {                //トークンの特権セット
    DWORD PrivilegeCount;       //特権の要素数
    LUID_AND_ATTRIBUTES Privileges[?]; //特権
} TOKEN_PRIVILEGES, *PTOKEN_PRIVILEGES;
//// プロトタイプ
//現在プロセスの擬似ハンドルを取得
HANDLE GetCurrentProcess(       //戻り値:現在プロセスのハンドル
    void);
//プロセスのアクセストークンを開く
BOOL OpenProcessToken(          //戻り値:成功したか
    HANDLE ProcessHandle,       //入力:プロセスハンドル
    DWORD DesiredAccess,        //入力:アクセス権
    PHANDLE TokenHandle);       //出力:トークンハンドル
//特権名からローカル一意識別子を探す
BOOL LookupPrivilegeValueA(     //戻り値:成功したか
    LPCSTR lpSystemName,        //入力:システムの名前
    LPCSTR lpName,              //入力:特権の名前
    PLUID lpLuid);              //出力:ローカル一意識別子
//アクセストークンを更新する [advapi32]
BOOL AdjustTokenPrivileges(     //戻り値:成功したか
    HANDLE TokenHandle,         //入力:特権トークンハンドル
    BOOL DisableAllPrivileges,  //入力:全特権を無効化するか
    PTOKEN_PRIVILEGES NewState, //出力:更新内容の特権情報
    DWORD BufferLength,         //入力:更新前のPreviousStateのサイズ
    PTOKEN_PRIVILEGES PreviousState, //入出力:更新対象の特権情報
    PDWORD ReturnLength);       //出力:更新後のPreviousStateのサイズ
//直近のエラーコードを取得
DWORD GetLastError(             //戻り値:直近のエラーコード
    void);
//システムのシャットダウンを行う
BOOL ExitWindowsEx(             //戻り値:成功したか
    UINT uFlags,                //入力:シャットダウン操作
    DWORD dwReserved);
]]
Ccst = { -- 定数定義
  TOKEN_ADJUST_PRIVILEGES = 0x0020;
  TOKEN_QUERY = 0x0008;
  SE_PRIVILEGE_ENABLED = 0x00000002;
  SE_SHUTDOWN_NAME = "SeShutdownPrivilege";
  ERROR_SUCCESS = 0;
  EWX_SHUTDOWN = 0x00000001;
  EWX_REBOOT = 0x00000002;
}
advapi32 = ffi.load("advapi32")

--- システムのシャットダウンを開始する
-- @return 成功したか
function shutdown_system()
  -- プロセストークンの取得
  local TokenHandle = ffi.new("HANDLE[1]")
  local ok = ffi.C.OpenProcessToken(ffi.C.GetCurrentProcess(),
      Ccst.TOKEN_ADJUST_PRIVILEGES + Ccst.TOKEN_QUERY, TokenHandle)
  if ok == 0 then return false end -- 失敗
  -- 必要な権限を取得する
  local Privileges = ffi.new("TOKEN_PRIVILEGES", 1)
  Privileges.PrivilegeCount = 1
  Privileges.Privileges[0].Attributes = Ccst.SE_PRIVILEGE_ENABLED
  ok = advapi32.LookupPrivilegeValueA(nil, Ccst.SE_SHUTDOWN_NAME,
      Privileges.Privileges[0].Luid)
  if ok == 0 then return false end -- 失敗
  advapi32.AdjustTokenPrivileges(TokenHandle[0], 0, Privileges,
      0, nil, nil)
    --※AdjustTokenPrivilegesはGetLastErrorの確認が必要
  if ffi.C.GetLastError() ~= Ccst.ERROR_SUCCESS then return false end -- 失敗
  -- シャットダウンを開始する
  ok = ffi.C.ExitWindowsEx(Ccst.EWX_SHUTDOWN, 0);
  return (ok ~= 0) -- 成功したか
end

-------- 使用例
print(shutdown_system())
-- EOF
