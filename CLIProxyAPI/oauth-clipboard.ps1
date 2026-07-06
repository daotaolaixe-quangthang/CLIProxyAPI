param(
    [Parameter(Mandatory=$true)]
    [string]$LoginFlag,

    [string]$Config = "",

    [switch]$InteractiveRelay
)

$exe = Join-Path $PSScriptRoot "cli-proxy-api.exe"

if ([string]::IsNullOrWhiteSpace($Config)) {
    $configPath = Join-Path $env:USERPROFILE ".cli-proxy-api\config.yaml"
} else {
    $configPath = $Config
}

$script:urlCopied = $false
$script:urlBuffer = ""

function Show-CopiedUrlNotice {
    param([string]$Url)

    try {
        Set-Clipboard -Value $Url
        Write-Host ""
        Write-Host "  ================================================" -ForegroundColor Green
        Write-Host "  [OK] URL da duoc COPY vao Clipboard tu dong!" -ForegroundColor Green
        Write-Host "  >>> Paste (Ctrl+V) vao browser profile ban muon" -ForegroundColor Cyan
        Write-Host "  ================================================" -ForegroundColor Green
        Write-Host ""
        $script:urlCopied = $true
    } catch {
        Write-Host ""
        Write-Host "  [WARN] Khong the copy URL vao Clipboard: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Try-CopyOAuthUrl {
    param([switch]$Final)

    if ($script:urlCopied) {
        return
    }

    if ($script:urlBuffer -notmatch 'https?://[^\s"<>]+') {
        return
    }

    $url = $Matches[0]

    if (-not $Final) {
        $start = $script:urlBuffer.IndexOf($url)
        $end = $start + $url.Length
        if ($end -ge $script:urlBuffer.Length) {
            return
        }
        if (-not [char]::IsWhiteSpace($script:urlBuffer[$end])) {
            return
        }
    }

    Show-CopiedUrlNotice -Url $url
}

function Add-OAuthOutputText {
    param([string]$Text)

    $script:urlBuffer += $Text
    if ($script:urlBuffer.Length -gt 8192) {
        $script:urlBuffer = $script:urlBuffer.Substring($script:urlBuffer.Length - 8192)
    }

    if ($Text -match '\s') {
        Try-CopyOAuthUrl
    }
}

function Quote-WindowsArg {
    param([string]$Value)

    if ($null -eq $Value) {
        return '""'
    }

    return '"' + ($Value -replace '"', '\"') + '"'
}

function Invoke-InteractiveRelay {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = "--config $(Quote-WindowsArg $configPath) $LoginFlag --no-browser"
    $psi.WorkingDirectory = $PSScriptRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = $true
    $psi.CreateNoWindow = $false

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    [void]$proc.Start()

    $stdoutBuffer = New-Object char[] 1
    $stderrBuffer = New-Object char[] 1
    $stdoutTask = $proc.StandardOutput.ReadAsync($stdoutBuffer, 0, 1)
    $stderrTask = $proc.StandardError.ReadAsync($stderrBuffer, 0, 1)
    $stdoutDone = $false
    $stderrDone = $false

    while (-not $proc.HasExited -or -not $stdoutDone -or -not $stderrDone) {
        if (-not $stdoutDone -and $stdoutTask.IsCompleted) {
            try {
                $count = $stdoutTask.Result
            } catch {
                $count = 0
            }

            if ($count -le 0) {
                $stdoutDone = $true
            } else {
                $text = [string]$stdoutBuffer[0]
                [Console]::Write($text)
                Add-OAuthOutputText -Text $text
                $stdoutBuffer = New-Object char[] 1
                $stdoutTask = $proc.StandardOutput.ReadAsync($stdoutBuffer, 0, 1)
            }
        }

        if (-not $stderrDone -and $stderrTask.IsCompleted) {
            try {
                $count = $stderrTask.Result
            } catch {
                $count = 0
            }

            if ($count -le 0) {
                $stderrDone = $true
            } else {
                $text = [string]$stderrBuffer[0]
                [Console]::Error.Write($text)
                Add-OAuthOutputText -Text $text
                $stderrBuffer = New-Object char[] 1
                $stderrTask = $proc.StandardError.ReadAsync($stderrBuffer, 0, 1)
            }
        }

        if (-not $proc.HasExited) {
            $hasKey = $false
            try {
                $hasKey = [Console]::KeyAvailable
            } catch {
                $hasKey = $false
            }

            if ($hasKey) {
                $line = [Console]::ReadLine()
                if ($null -ne $line) {
                    $proc.StandardInput.WriteLine($line)
                    $proc.StandardInput.Flush()
                }
            }
        }

        Start-Sleep -Milliseconds 15
    }

    Try-CopyOAuthUrl -Final
    $proc.WaitForExit()
    exit $proc.ExitCode
}

Write-Host ""
Write-Host "  [READY] Dang khoi dong OAuth - cho URL xuat hien..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  [INFO] Exe  : $exe" -ForegroundColor DarkGray
Write-Host "  [INFO] Config: $configPath" -ForegroundColor DarkGray
Write-Host ""

if ($InteractiveRelay) {
    Invoke-InteractiveRelay
}

& $exe --config $configPath $LoginFlag --no-browser 2>&1 | ForEach-Object {
    $line = "$_"
    Write-Host $line
    Add-OAuthOutputText -Text ($line + [Environment]::NewLine)
}

$exitCode = $LASTEXITCODE
Try-CopyOAuthUrl -Final
exit $exitCode
