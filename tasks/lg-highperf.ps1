# LG Gram 냉각 모드 '고성능' 직접 적용 — ACPI WMI 방식
# 로그온 시 작업스케줄러 LG-HighPerf-OnLogon 이 실행.
#
# 배경: LG Control Center 는 재부팅마다 냉각 모드를 '권장'으로 초기화함.
#       구버전 스크립트는 LG CC 창을 띄워 '고성능' 버튼을 합성 클릭했으나,
#       LG CC 바이너리(LGDeviceCtrlLib.dll)를 디컴파일해 실제 ACPI 호출을
#       확인 → UI 없이 EC 레지스터를 직접 제어한다(창 깜빡임/클릭 빗나감 없음).
#
# 원리 — LGDeviceController.Set_SystemTempMode 로직을 그대로 복제(추측 아님):
#   root\WMI 클래스 Method_ULong2 (디바이스 ACPI\LGEX0820).
#   읽기: GetULong(InOffset=1036)               -> OutData & 0xFF
#                                                  0=권장 1=저소음 2=고성능
#   쓰기: num2 = (OutData & 0xFFFFFF00) -bor 2   (상위 바이트 보존 + 고성능)
#         SetULong(InOffset=1036, InData=num2, Flags=1)
#   쓰기 후 다시 읽어 lowByte=2 확인 = 적용 성공.
# 로그: %LOCALAPPDATA%\lg-highperf.log

$ErrorActionPreference = 'Stop'
$OFF  = 1036   # 0x40C — 냉각 모드 레지스터 오프셋
$PERF = 2      # 고성능
$log  = Join-Path $env:LOCALAPPDATA 'lg-highperf.log'
function Log($m){ "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File -FilePath $log -Append -Encoding utf8 }

function Get-Inst { @(Get-WmiObject -Namespace 'root\WMI' -Class 'Method_ULong2')[0] }

function Read-Raw {
  $i = Get-Inst
  if(-not $i){ throw 'Method_ULong2 인스턴스 없음' }
  $p = $i.GetMethodParameters('GetULong'); $p['InOffset'] = $OFF
  $r = $i.InvokeMethod('GetULong', $p, $null)
  if([int64]$r['OutStatus'] -ne 0){ throw "GetULong OutStatus=$([int64]$r['OutStatus'])" }
  return [int64]$r['OutData']
}

function Write-Raw([int]$val){
  $i = Get-Inst
  if(-not $i){ throw 'Method_ULong2 인스턴스 없음' }
  $p = $i.GetMethodParameters('SetULong')
  $p['InOffset'] = $OFF; $p['InData'] = $val; $p['Flags'] = 1
  $r = $i.InvokeMethod('SetULong', $p, $null)
  return [int64]$r['OutStatus']
}

try {
  Log '=== start (ACPI) ==='
  $cur = Read-Raw
  Log ('현재 raw=0x{0:X} mode={1}' -f $cur, ($cur -band 0xFF))

  if(($cur -band 0xFF) -eq $PERF){
    Log '=== done: 이미 고성능 ==='
    exit 0
  }

  # 상위 바이트(0x10000 등 디바이스 플래그)는 보존하고 하위 바이트만 고성능으로
  $num2 = ($cur -band 0xFFFFFF00) -bor $PERF
  $ok = $false
  for($try = 1; $try -le 3 -and -not $ok; $try++){
    $st   = Write-Raw ([int]$num2)
    Start-Sleep -Milliseconds 500
    $back = Read-Raw
    Log ('SetULong try {0}: InData=0x{1:X} OutStatus={2} -> readback=0x{3:X} mode={4}' -f $try, $num2, $st, $back, ($back -band 0xFF))
    if($st -eq 0 -and ($back -band 0xFF) -eq $PERF){ $ok = $true }
    else { Start-Sleep 1 }
  }

  if($ok){ Log '=== done: 고성능 적용 성공 ==='; exit 0 }
  else   { Log '=== done: 고성능 적용 실패 (수동 확인 필요) ==='; exit 2 }
} catch {
  Log "ERROR: $_"
  exit 1
}
