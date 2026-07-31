param(
    [string]$OutDir = "$PSScriptRoot\结果",
    [string]$RunId = '',
    [string]$Version = ''   # 版本后缀（如 v20260731.3.5.30），缺省取 RunId，确保历史产物永不覆盖
)

$ErrorActionPreference = 'Stop'
$repo = 'Feng-WeiHang/know_sky-ios'

# resolve token from git credential store
$cred = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
$tok = ($cred | Select-String '^password=').ToString().Substring(9)
$hdr = @{ Authorization = "token $tok"; 'User-Agent' = 'SkySense' }

# default: latest successful run on main
if (-not $RunId) {
    $runs = (Invoke-RestMethod "https://api.github.com/repos/$repo/actions/runs?status=success&per_page=1" -Headers $hdr).workflow_runs
    if (-not $runs) { throw 'no successful run found' }
    $RunId = $runs[0].id
    Write-Host "using latest successful run $RunId ($($runs[0].head_sha.Substring(0,7)))"
}

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
if (-not $Version) { $Version = "run$RunId" }

$arts = (Invoke-RestMethod "https://api.github.com/repos/$repo/actions/runs/$RunId/artifacts" -Headers $hdr).artifacts
foreach ($a in $arts) {
    # 历史版本一律保留：文件名带版本后缀，若目标已存在则报错而非覆盖
    $dest = Join-Path $OutDir "$($a.name)_$Version.zip"
    if (Test-Path $dest) { throw "refuse to overwrite existing artifact: $dest" }
    # .NET drops the Authorization header on cross-host redirect, so following redirects is safe
    Invoke-WebRequest -Uri $a.archive_download_url -Headers $hdr -OutFile $dest -UseBasicParsing
    $size = [math]::Round((Get-Item $dest).Length / 1MB, 2)
    Write-Host "saved $($a.name)_$Version.zip ($size MB)"
}
