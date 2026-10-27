# installer-smoke.ps1 — the Windows installer, run the way a person and an administrator's script run it.
#
#   pwsh installer-smoke.ps1 -Setup Shoalcheck_<v>_windows_<arch>_setup.exe -Version <v>
#
# Installs silently, checks every promise the installer makes (the files, the Start menu, PATH, Apps & features),
# runs the installed command line and the installed window's server, installs again OVER A RUNNING COPY (the
# upgrade path), and uninstalls silently, checking that it took back what it put there and nothing else.
#
# Two copies, one text: packaging/windows/installer-smoke.ps1 (CI's windows-smoke job) and
# docs/launch/public/smoke/installer-smoke.ps1 (release-smoke, in Shoalcheck/shoalcheck as .github/smoke/).
param(
  [Parameter(Mandatory = $true)] [string] $Setup,
  [Parameter(Mandatory = $true)] [string] $Version
)
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'Programs\Shoalcheck'
$uninstKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Shoalcheck'
$startMenu = Join-Path ([Environment]::GetFolderPath('Programs')) 'Shoalcheck.lnk'
$port = 47813
$tmp = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }

function Fail([string] $m) { Write-Host "::error::$m"; exit 1 }
function UserPath { [Environment]::GetEnvironmentVariable('Path', 'User') }
function OnPath { (UserPath) -split ';' -contains $dir }
function Install {
  $p = Start-Process -FilePath $Setup -ArgumentList '/S' -Wait -PassThru
  if ($p.ExitCode -ne 0) { Fail "the installer (/S) exited $($p.ExitCode)" }
}
function Serves {
  for ($i = 0; $i -lt 60; $i++) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$port/" -TimeoutSec 2
      if ($r.StatusCode -eq 200) { return $r.Content }
    } catch { Start-Sleep -Milliseconds 500 }
  }
  return $null
}

$before = UserPath
Write-Host "installing $Setup (user PATH before: $($before.Length) characters)"
Install
foreach ($f in 'shoalcheck-app.exe', 'shoalcheck.exe', 'kubectl-shoalcheck.exe', 'uninstall.exe', 'shoalcheck.ico', 'LICENSE', 'NOTICE') {
  if (-not (Test-Path (Join-Path $dir $f))) { Fail "$f is not in $dir" }
}
if (-not (Test-Path $startMenu)) { Fail "no Start menu shortcut at $startMenu" }
$k = Get-ItemProperty $uninstKey
if ($k.DisplayVersion -ne $Version) { Fail "Apps & features lists version '$($k.DisplayVersion)', not $Version" }
if ($k.QuietUninstallString -notmatch 'uninstall\.exe" /S$') { Fail "no quiet uninstall string: $($k.QuietUninstallString)" }
if (-not (OnPath)) { Fail "the user PATH does not carry $dir : $(UserPath)" }
$v = & (Join-Path $dir 'shoalcheck.exe') --version
if ("$v" -notmatch [regex]::Escape($Version)) { Fail "the installed shoalcheck --version says: $v" }
$v = & (Join-Path $dir 'kubectl-shoalcheck.exe') --version
if ("$v" -notmatch [regex]::Escape($Version)) { Fail "the installed kubectl-shoalcheck --version says: $v" }
Write-Host "installed: files, Start menu, Apps & features ($($k.DisplayVersion)), PATH, both command lines answer"

# The installed window's server, headless: the window itself needs a desktop, which a runner may not give it.
$app = Start-Process -FilePath (Join-Path $dir 'shoalcheck-app.exe') -ArgumentList '--no-open', '--addr', "127.0.0.1:$port" `
  -PassThru -RedirectStandardOutput (Join-Path $tmp 'installed-app.out') -RedirectStandardError (Join-Path $tmp 'installed-app.err')
$page = Serves
if (-not $page -or $page -notmatch '<title>Shoalcheck</title>' -or $page -notmatch 'name="shoalcheck-session"') {
  Get-Content (Join-Path $tmp 'installed-app.out'), (Join-Path $tmp 'installed-app.err') -ErrorAction SilentlyContinue
  Fail 'the installed app did not serve its page with a session token'
}
Write-Host "the installed app serves on 127.0.0.1:$port"

# UPGRADE OVER A RUNNING COPY: the running file is put aside, never killed, and the new one is in place.
Install
if (-not (Test-Path (Join-Path $dir 'shoalcheck-app.exe.old'))) { Fail 'the running app was not put aside as shoalcheck-app.exe.old' }
if ($app.HasExited) { Fail 'installing over the running app stopped it' }
if (-not (Serves)) { Fail 'the running app stopped answering during the upgrade' }
if (((UserPath) -split ';' | Where-Object { $_ -eq $dir }).Count -ne 1) { Fail "the upgrade added $dir to PATH twice: $(UserPath)" }
Write-Host 'upgraded in place over a running copy; it kept serving'
Stop-Process -Id $app.Id -Force
$app.WaitForExit()

# UNINSTALL, silently. _? runs the uninstaller where it is and waits for it; the uninstaller itself then remains.
$p = Start-Process -FilePath (Join-Path $dir 'uninstall.exe') -ArgumentList '/S', "_?=$dir" -Wait -PassThru
if ($p.ExitCode -ne 0) { Fail "the uninstaller exited $($p.ExitCode)" }
foreach ($f in 'shoalcheck-app.exe', 'shoalcheck-app.exe.old', 'shoalcheck.exe', 'kubectl-shoalcheck.exe', 'shoalcheck.ico', 'NOTICE') {
  if (Test-Path (Join-Path $dir $f)) { Fail "$f is still in $dir after uninstalling" }
}
if (Test-Path $startMenu) { Fail 'the Start menu shortcut survived the uninstall' }
if (Test-Path $uninstKey) { Fail 'Apps & features still lists Shoalcheck' }
if (OnPath) { Fail "the uninstall left $dir on PATH: $(UserPath)" }
if ((UserPath) -ne $before) { Fail "the uninstall did not give PATH back as it was:`n before: $before`n after:  $(UserPath)" }
Remove-Item -Force (Join-Path $dir 'uninstall.exe')
Write-Host 'uninstalled: files, shortcut, Apps & features entry and PATH entry gone; PATH as it was before'
