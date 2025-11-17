# Pode Module Fix Tool for PowerShell 5.1
# Fixes Console.ps1 encoding issues

param([switch]$Uninstall)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Pode Module Fix Tool" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$podeModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode"
$podeConsoleFile = "$podeModulePath\2.12.1\Private\Console.ps1"

if ($Uninstall) {
    Write-Host "[1/2] Uninstalling Pode module..." -ForegroundColor Yellow

    if (Get-Module Pode) {
        Remove-Module Pode -Force -ErrorAction SilentlyContinue
        Write-Host "  OK Removed from memory" -ForegroundColor Gray
    }

    Uninstall-Module -Name Pode -AllVersions -Force -ErrorAction SilentlyContinue
    Write-Host "  OK Uninstalled" -ForegroundColor Gray

    if (Test-Path $podeModulePath) {
        Remove-Item $podeModulePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  OK Deleted directory" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "[2/2] Reinstalling Pode module..." -ForegroundColor Yellow
    Install-Module -Name Pode -Scope CurrentUser -Force -AllowClobber
    Write-Host "  OK Installation complete" -ForegroundColor Green
    Write-Host ""
}

Write-Host "[FIX] Fixing Console.ps1..." -ForegroundColor Cyan

if (-not (Test-Path $podeConsoleFile)) {
    Write-Host "[ERROR] Console.ps1 not found: $podeConsoleFile" -ForegroundColor Red
    Write-Host "        Please run with -Uninstall option first" -ForegroundColor Yellow
    exit 1
}

try {
    # Create backup
    $backupFile = "$podeConsoleFile.backup"
    if (-not (Test-Path $backupFile)) {
        Copy-Item $podeConsoleFile $backupFile -Force
        Write-Host "  OK Backup created" -ForegroundColor Gray
    }

    # Read file as binary
    $bytes = [System.IO.File]::ReadAllBytes($podeConsoleFile)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)

    # Process line by line
    $lines = $content -split "`r?`n"
    $fixedLines = @()
    $lineNumber = 0
    $replacedCount = 0

    foreach ($line in $lines) {
        $lineNumber++
        $originalLine = $line

        # Replace all problematic Unicode characters with ASCII equivalents
        # Box Drawing characters
        $line = $line -replace ([char]0x2500), '-'
        $line = $line -replace ([char]0x2501), '-'
        $line = $line -replace ([char]0x2502), '|'
        $line = $line -replace ([char]0x2503), '|'

        # Dashes
        $line = $line -replace ([char]0x2013), '-'  # En dash
        $line = $line -replace ([char]0x2014), '-'  # Em dash
        $line = $line -replace ([char]0x2212), '-'  # Minus sign

        # Apostrophes and quotes (critical for line 482)
        $line = $line -replace ([char]0x2018), "'"  # Left single quote
        $line = $line -replace ([char]0x2019), "'"  # Right single quote (apostrophe)
        $line = $line -replace ([char]0x201C), '"'  # Left double quote
        $line = $line -replace ([char]0x201D), '"'  # Right double quote

        # For lines 460-470, handle problematic quoted characters
        if ($lineNumber -ge 460 -and $lineNumber -le 470) {
            # Remove quoted non-ASCII characters like '─'
            $line = $line -replace "'[^\x00-\x7F]+'", "''"
            $line = $line -replace '"[^\x00-\x7F]+"', '""'
        }

        if ($originalLine -ne $line) {
            $replacedCount++
        }

        $fixedLines += $line
    }

    # Save with UTF-8 without BOM (module files should not have BOM)
    $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($podeConsoleFile, $fixedLines, $utf8NoBOM)

    Write-Host ""
    if ($replacedCount -gt 0) {
        Write-Host "[SUCCESS] Fixed Console.ps1 ($replacedCount changes)" -ForegroundColor Green
    } else {
        Write-Host "[INFO] No changes needed" -ForegroundColor Gray
    }

    # Verify the fix
    Write-Host ""
    Write-Host "[TEST] Testing Pode module..." -ForegroundColor Cyan

    if (Get-Module Pode) {
        Remove-Module Pode -Force
    }

    Import-Module Pode -ErrorAction Stop
    $version = (Get-Module Pode).Version

    Write-Host "[SUCCESS] Pode module loaded successfully (Version: $version)" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Fix completed!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "[ERROR] Fix failed" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Retry with:" -ForegroundColor Yellow
    Write-Host "  .\Fix-PodeModule-Simple.ps1 -Uninstall" -ForegroundColor Yellow
    exit 1
}
