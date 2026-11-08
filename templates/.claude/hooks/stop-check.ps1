# Stop / SubagentStop hook：在任务分支上跑检查命令，不通过则 exit 2 让 Claude 继续修。
# 在 main/master 或没有检查命令时直接放行（总控、讨论、设计会话不受影响）。
$inputJson = [Console]::In.ReadToEnd()
$payload = $null
if ($inputJson -and $inputJson.Trim()) { try { $payload = $inputJson | ConvertFrom-Json } catch { $payload = $null } }
if ($payload -and $payload.stop_hook_active -eq $true) { exit 0 }

$branch = (git rev-parse --abbrev-ref HEAD 2>$null)
if (-not $branch -or $branch -in @('main', 'master', 'HEAD')) { exit 0 }

$cfg = 'docs/memory/CHECK_CMD.txt'
if (-not (Test-Path $cfg)) { exit 0 }
# NOTE: PowerShell 5.1 reads BOM-less files as ANSI (GBK); a Chinese comment line can swallow its newline.
# So: this script is saved as UTF-8 *with BOM*, CHECK_CMD.txt is read with -Encoding UTF8,
# and the command is passed via -EncodedCommand so its double quotes survive.
$cmd = ((Get-Content $cfg -Raw -Encoding UTF8) -split "`n" | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } | Select-Object -First 1)
if (-not $cmd) { exit 0 }
$cmd = $cmd.Trim()

$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
$out = & powershell -NoProfile -EncodedCommand $enc 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("CHECK FAILED - fix the problems below before finishing. Command: $cmd")
    [Console]::Error.WriteLine($out)
    exit 2
}
exit 0
