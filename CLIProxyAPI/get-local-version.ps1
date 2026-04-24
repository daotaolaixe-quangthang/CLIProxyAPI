# get-local-version.ps1
# Doc version local cua cli-proxy-api.exe va ghi ra stdout
param([string]$ExePath)
try {
    $output = & $ExePath --version 2>&1 | Out-String
    $m = [regex]::Match($output, 'Version:\s*([\d.]+)')
    if ($m.Success) { $m.Groups[1].Value } else { 'unknown' }
} catch { 'unknown' }
