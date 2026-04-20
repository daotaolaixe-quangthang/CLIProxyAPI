param(
    [Parameter(Mandatory=$true)]
    [string]$LoginFlag
)

$exe    = "E:\CLIProxyAPI\cli-proxy-api.exe"
$config = "C:\Users\Admin\.cli-proxy-api\config.yaml"
$global:urlCopied = $false

Write-Host ""
Write-Host "  [READY] Dang khoi dong OAuth - cho URL xuat hien..." -ForegroundColor Yellow
Write-Host ""

& $exe --config $config $LoginFlag --no-browser 2>&1 | ForEach-Object {
    $line = "$_"
    Write-Host $line

    # Phat hien URL bat dau bang https:// hoac http://
    if (-not $global:urlCopied -and $line -match 'https?://[^\s"]+') {
        $url = $Matches[0]

        # Tu dong copy vao Clipboard
        Set-Clipboard -Value $url

        Write-Host ""
        Write-Host "  ================================================" -ForegroundColor Green
        Write-Host "  [OK] URL da duoc COPY vao Clipboard tu dong!"     -ForegroundColor Green
        Write-Host "  >>> Paste (Ctrl+V) vao browser profile ban muon"  -ForegroundColor Cyan
        Write-Host "  ================================================" -ForegroundColor Green
        Write-Host ""

        $global:urlCopied = $true
    }
}
