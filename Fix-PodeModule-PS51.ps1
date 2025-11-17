# Pode Module Fix Tool for PowerShell 5.1
# Installs Pode 2.11.0 (last version with full PS 5.1 support)
# and fixes encoding issues

param([switch]$Uninstall)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Pode 2.11.0 Setup Tool (PS 5.1 Compatible)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$podeVersion = "2.11.0"

if ($Uninstall) {
    Write-Host "[1/2] Uninstalling all Pode versions..." -ForegroundColor Yellow

    if (Get-Module Pode) {
        Remove-Module Pode -Force -ErrorAction SilentlyContinue
        Write-Host "  OK Removed from memory" -ForegroundColor Gray
    }

    Uninstall-Module -Name Pode -AllVersions -Force -ErrorAction SilentlyContinue
    Write-Host "  OK Uninstalled" -ForegroundColor Gray

    # Delete all Pode module directories
    $possiblePaths = @(
        "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode",
        "$env:ProgramFiles\WindowsPowerShell\Modules\Pode"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  OK Deleted directory: $path" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "[2/2] Installing Pode $podeVersion (PowerShell 5.1 compatible)..." -ForegroundColor Yellow
    Install-Module -Name Pode -RequiredVersion $podeVersion -Scope CurrentUser -Force -AllowClobber
    Write-Host "  OK Installation complete" -ForegroundColor Green
    Write-Host ""
}

Write-Host "[FIX] Fixing Console.ps1..." -ForegroundColor Cyan

# Auto-detect Pode installation path
$podeModule = Get-Module Pode -ListAvailable | Where-Object { $_.Version -eq $podeVersion } | Select-Object -First 1
if (-not $podeModule) {
    Write-Host "[ERROR] Pode $podeVersion not found" -ForegroundColor Red
    Write-Host "        Please run with -Uninstall option first" -ForegroundColor Yellow
    exit 1
}

$podeConsoleFile = Join-Path (Split-Path $podeModule.Path -Parent) "Private\Console.ps1"
Write-Host "  Checking: $podeConsoleFile" -ForegroundColor Gray

if (-not (Test-Path $podeConsoleFile)) {
    Write-Host "[INFO] Console.ps1 not found in Pode $podeVersion" -ForegroundColor Gray
    Write-Host "       This version does not have encoding issues - no fix needed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Pode $podeVersion is ready to use!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    exit 0
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

        # Apostrophes and quotes
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
    Write-Host "[TEST] Testing Pode $podeVersion module..." -ForegroundColor Cyan

    if (Get-Module Pode) {
        Remove-Module Pode -Force
    }

    Import-Module Pode -ErrorAction Stop
    $version = (Get-Module Pode).Version

    Write-Host "[SUCCESS] Pode module loaded successfully (Version: $version)" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "PowerShell 5.1 compatible setup complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "[ERROR] Fix failed" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Retry with:" -ForegroundColor Yellow
    Write-Host "  .\Fix-PodeModule-PS51.ps1 -Uninstall" -ForegroundColor Yellow
    exit 1
}
