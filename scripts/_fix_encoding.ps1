# UTF-8 -> GBK encoding converter (idempotent safe version)
# Uses strict UTF-8 decoder: if file is already GBK, decoding fails and file is skipped
# Safe to run multiple times without double-conversion
param([string]$Dir = (Split-Path -Parent $MyInvocation.MyCommand.Path))

$gbk = [Text.Encoding]::GetEncoding('gb2312')
# throwOnInvalidBytes = true: GBK bytes that are invalid UTF-8 will throw exception
$utf8Strict = New-Object Text.UTF8Encoding($false, $true)
$count = 0; $skipped = 0

foreach ($f in (Get-ChildItem "$Dir\*.bat")) {
    $bytes = [IO.File]::ReadAllBytes($f.FullName)

    # 1. Skip pure ASCII files (no Chinese, no conversion needed)
    $hasHighByte = $false
    foreach ($b in $bytes) { if ($b -gt 127) { $hasHighByte = $true; break } }
    if (-not $hasHighByte) {
        Write-Host "SKIP (ASCII only): $($f.Name)"
        $skipped++
        continue
    }

    # 2. Strict UTF-8 decode - if file is already GBK, this will throw
    try {
        $decoded = $utf8Strict.GetString($bytes)
    } catch {
        Write-Host "SKIP (already GBK): $($f.Name)"
        $skipped++
        continue
    }

    # 3. Decode succeeded = file is UTF-8, convert to GBK
    [IO.File]::WriteAllText($f.FullName, $decoded, $gbk)
    Write-Host "CONVERTED: $($f.Name)"
    $count++
}

Write-Host ""
Write-Host "Done: converted $count file(s), skipped $skipped file(s)"
