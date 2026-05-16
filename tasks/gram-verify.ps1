# 그램 체감속도 최적화 — 재부팅 후 검증 스크립트
# 사용법: 재부팅 후 PowerShell에서  powershell -ExecutionPolicy Bypass -File <이 파일>
# 작성: 2026-05-16 그램 최적화 세션

function Check($label, $cond, $detail){
  $mark = if($cond){ 'OK  ' } else { 'FAIL' }
  "{0}  {1}  {2}" -f $mark, $label, $detail
}

"===== 그램 최적화 검증 ($(Get-Date)) ====="
""
"--- 전원 / CPU ---"
$scheme = (powercfg /getactivescheme)
Check '고성능 전원 구성표' ($scheme -match '고성능|High perf') $scheme
$g = ((powercfg /getactivescheme) -split 'GUID: ')[1].Split(' ')[0]
$pmin = (powercfg /q $g SUB_PROCESSOR PROCTHROTTLEMIN | Select-String 'AC') -join ''
$pmax = (powercfg /q $g SUB_PROCESSOR PROCTHROTTLEMAX | Select-String 'AC') -join ''
Check 'CPU 최대 상태 100%' ($pmax -match '0x00000064') $pmax.Trim()

""
"--- 서비스 (체감/발열) ---"
foreach($s in 'DiagTrack','ESRV_SVC_QUEENCREEK'){
  $svc = Get-Service $s -EA SilentlyContinue
  Check "$s 비활성" ($svc -and $svc.StartType -eq 'Disabled') ($(if($svc){"StartType=$($svc.StartType)"}else{'없음'}))
}
foreach($s in 'MACOURTSAFER_Svc','KollusSvr','NetFileService','AnySign4PC Launcher','INISAFEClientManager','Interezen_service'){
  $svc = Get-Service $s -EA SilentlyContinue
  Check "$s 수동화" ($svc -and $svc.StartType -eq 'Manual') ($(if($svc){"StartType=$($svc.StartType)"}else{'없음'}))
}
$dtt = Get-Service esifsvc -EA SilentlyContinue
Check 'Intel DTT(esifsvc) 정상 가동' ($dtt -and $dtt.Status -eq 'Running') ($(if($dtt){"$($dtt.Status)"}else{'없음'}))

""
"--- 시작 항목 ---"
$sa = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
foreach($n in 'ZeroTierUI','Teams'){
  $v = (Get-ItemProperty $sa -Name $n -EA SilentlyContinue).$n
  Check "$n 자동시작 OFF" ($v -and ($v[0] -band 1)) ($(if($v){'disabled'}else{'미설정(enabled)'}))
}

""
"--- 시각 / 체감 UI ---"
Check '시각효과 성능우선' ((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -EA 0).VisualFXSetting -eq 2) ''
Check '투명효과 OFF' ((Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name EnableTransparency -EA 0).EnableTransparency -eq 0) ''
Check 'GameDVR OFF' ((Get-ItemProperty 'HKCU:\System\GameConfigStore' -Name GameDVR_Enabled -EA 0).GameDVR_Enabled -eq 0) ''
Check '시작메뉴 웹검색 OFF' ((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name BingSearchEnabled -EA 0).BingSearchEnabled -eq 0) ''
Check '백그라운드 앱 OFF' ((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' -Name GlobalUserDisabled -EA 0).GlobalUserDisabled -eq 1) ''

""
"--- 제거 확인 ---"
Check 'OneDrive 제거됨' (-not (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe")) ''
Check 'ThrottleStop 제거됨' (-not (Test-Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\TechPowerUp.ThrottleStop_Microsoft.Winget.Source_8wekyb3d8bbwe")) ''

""
"--- 네트워크 어댑터 절전 (이전 세션 설정, 부팅 적용) ---"
$nic = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' -Name PnPCapabilities -EA SilentlyContinue
Check 'NIC 절전 해제(PnPCapabilities=256)' ($nic.PnPCapabilities -eq 256) ($(if($nic){"=$($nic.PnPCapabilities)"}else{'미설정'}))

""
"--- 냉각 모드 (ACPI 직접 읽기, LG CC 불필요) ---"
try {
  $mi = @(Get-WmiObject -Namespace 'root\WMI' -Class 'Method_ULong2')[0]
  $mp = $mi.GetMethodParameters('GetULong'); $mp['InOffset'] = 1036
  $mr = $mi.InvokeMethod('GetULong', $mp, $null)
  $low = ([int64]$mr['OutData']) -band 0xFF
  $nm = @{0='권장';1='저소음';2='고성능'}[[int]$low]
  Check '냉각 모드 = 고성능' ($low -eq 2) ("mode=$low ($nm), raw=0x{0:X}" -f [int64]$mr['OutData'])
} catch {
  Check '냉각 모드 ACPI 읽기' $false $_.Exception.Message
}

""
"--- 자원 현황 ---"
$os = Get-CimInstance Win32_OperatingSystem
"유휴 CPU 부하: $((Get-CimInstance Win32_Processor).LoadPercentage)%"
"여유 RAM: $([math]::Round($os.FreePhysicalMemory/1KB)) MB / $([math]::Round($os.TotalVisibleMemorySize/1KB)) MB"
"가동 시간: $([math]::Round(((Get-Date)-$os.LastBootUpTime).TotalMinutes,1)) 분"
""
"참고: Defender 예외(C:\Users\wh850\CLAUDE)는 관리자 PowerShell에서  (Get-MpPreference).ExclusionPath  로 확인."
"===== 검증 끝 ====="
