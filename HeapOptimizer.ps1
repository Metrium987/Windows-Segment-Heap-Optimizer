<#
.SYNOPSIS
    Segment Heap Optimizer - Ultimate Expert Edition
.DESCRIPTION
    Advanced memory optimization tool for Windows 10 & 11.
.AUTHOR
    METAPLAYER987
#>

# --- FIX ENCODING ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- AUTO-ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    exit
}

$SMPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$SHPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Segment Heap"

# --- DATA ---
$Defaults = @{
    HeapSegmentReserve              = 1024  
    HeapSegmentCommit               = 8     
    HeapDeCommitTotalFreeThreshold  = 64    
    HeapDeCommitFreeBlockThreshold  = 4     
}

# --- FUNCTIONS ---
function Get-CurrentValue($Name) {
    $val = Get-ItemProperty -Path $SMPath -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $val.$Name) { return $Defaults[$Name] * 1024 }
    return $val.$Name
}

function Export-Backup {
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupName = "$PSScriptRoot\Backup_Heap_$Timestamp.reg"
    Write-Host "[-] Creating versioned backup: $BackupName" -NoNewline
    reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" "$BackupName" /y | Out-Null
    Write-Host " [OK]" -ForegroundColor Green
}

function Confirm-And-Apply {
    param($Name, $Reserve, $Commit, $Total, $Block, $IsDefault = $false)
    
    Clear-Host
    Write-Host "!!! PENDING MODIFICATIONS: $Name !!!" -ForegroundColor Cyan
    $Review = @()
    if ($IsDefault) {
        $Review += [PSCustomObject]@{Setting="Mode";Value="Windows Factory Defaults";Note="Standard Stability"}
    } else {
        $Review += [PSCustomObject]@{Setting="Commit";Value="$($Commit/1024) KiB";Note="Targeted Latency"}
        $Review += [PSCustomObject]@{Setting="Total Threshold";Value="$($Total/1024) KiB";Note="Cleanup Trigger"}
        $Review += [PSCustomObject]@{Setting="Block Threshold";Value="$($Block/1024) KiB";Note="Min Block Size"}
    }
    $Review | Format-Table -AutoSize

    Write-Host "Would you like to create a backup before applying?" -ForegroundColor Yellow
    $bkp = Read-Host "(Y)es / (N)o / (C)ancel"
    if ($bkp -eq "C") { return }
    if ($bkp -eq "Y") { Export-Backup }

    $confirm = Read-Host "`nConfirm application of '$Name'? (Y/N)"
    if ($confirm -eq "Y") {
        if ($IsDefault) {
            Set-ItemProperty -Path $SHPath -Name "Enabled" -Value 1 -Type DWord
            $Params = @("HeapSegmentReserve", "HeapSegmentCommit", "HeapDeCommitTotalFreeThreshold", "HeapDeCommitFreeBlockThreshold")
            foreach ($P in $Params) { Remove-ItemProperty -Path $SMPath -Name $P -ErrorAction SilentlyContinue }
        } else {
            if (-not (Test-Path $SHPath)) { New-Item -Path $SHPath -Force | Out-Null }
            Set-ItemProperty -Path $SHPath -Name "Enabled" -Value 1 -Type DWord
            Set-ItemProperty -Path $SMPath -Name "HeapSegmentReserve" -Value $Reserve -Type DWord
            Set-ItemProperty -Path $SMPath -Name "HeapSegmentCommit" -Value $Commit -Type DWord
            Set-ItemProperty -Path $SMPath -Name "HeapDeCommitTotalFreeThreshold" -Value $Total -Type DWord
            Set-ItemProperty -Path $SMPath -Name "HeapDeCommitFreeBlockThreshold" -Value $Block -Type DWord
        }
        Write-Host "--- Settings applied successfully! ---" -ForegroundColor Green
        Write-Host "!!! REBOOT REQUIRED to take effect !!!" -ForegroundColor Red
        Read-Host "Press Enter to return to menu..."
    }
}

function Show-Header { param($Title) Write-Host "`n=== $Title ===" -ForegroundColor Cyan }

function Expert-Mode {
    Clear-Host
    Write-Host "=================================================================================" -ForegroundColor Red
    Write-Host "                    EXPERT MODE - CURRENT SYSTEM STATE (KiB)                     " -ForegroundColor Red
    Write-Host "=================================================================================" -ForegroundColor Red
    
    $Fmt = "{0,-22} | {1,-8} | {2,-6} | {3,-6} | {4,-10} | {5,-15}"
    Write-Host ($Fmt -f "PARAMETER", "CURRENT", "MIN", "MAX", "DEFAULT", "RECOMMENDED") -ForegroundColor Gray
    Write-Host ("-" * 85)
    Write-Host ($Fmt -f "1. Commit", "$((Get-CurrentValue 'HeapSegmentCommit')/1024)", "2", "64", "8", "16 or 32")
    Write-Host ($Fmt -f "2. Reserve", "$((Get-CurrentValue 'HeapSegmentReserve')/1024)", "256", "4096", "1024", "1024")
    Write-Host ($Fmt -f "3. Total Threshold", "$((Get-CurrentValue 'HeapDeCommitTotalFreeThreshold')/1024)", "8", "512", "64", "32")
    Write-Host ($Fmt -f "4. Block Threshold", "$((Get-CurrentValue 'HeapDeCommitFreeBlockThreshold')/1024)", "1", "32", "4", "2 or 4")
    Write-Host ("-" * 85)

    Show-Header "1. HeapSegmentCommit"
    Write-Host "   [HELP] Sets the size of memory chunks the CPU prepares at once." -ForegroundColor Gray
    Write-Host "   [RULES] Min: 2 | Max: 64 | Windows Default: 8" -ForegroundColor Yellow
    Write-Host "   [REC.]  Use 16 for Mid-range or 32 for High-End CPUs." -ForegroundColor Green
    $vCommit = Read-Host "   >> Enter Value (KiB)"
    
    Show-Header "2. HeapSegmentReserve"
    Write-Host "   [HELP] Total virtual space reserved for the heap." -ForegroundColor Gray
    Write-Host "   [RULES] Min: 256 | Max: 4096 | Windows Default: 1024" -ForegroundColor Yellow
    Write-Host "   [REC.]  Keep at 1024. Use 2048 ONLY if you have 64GB+ of RAM." -ForegroundColor Green
    $vRes = Read-Host "   >> Enter Value (KiB)"

    Show-Header "3. HeapDeCommitTotalFreeThreshold"
    Write-Host "   [HELP] Total free memory limit before Windows starts cleaning up." -ForegroundColor Gray
    Write-Host "   [RULES] Min: 8 | Max: 512 | Windows Default: 64" -ForegroundColor Yellow
    Write-Host "   [REC.]  Use 32 for Ultimate Gaming (Aggressive) or 64 for Balanced." -ForegroundColor Green
    $vTotal = Read-Host "   >> Enter Value (KiB)"

    Show-Header "4. HeapDeCommitFreeBlockThreshold"
    Write-Host "   [HELP] Minimum size of an individual empty block to be cleaned." -ForegroundColor Gray
    Write-Host "   [RULES] Min: 1 | Max: 32 | Windows Default: 4" -ForegroundColor Yellow
    Write-Host "   [REC.]  Use 2 (if you set Total Threshold to 32) or 4 (if you set it to 64)." -ForegroundColor Green
    $vBlock = Read-Host "   >> Enter Value (KiB)"

    $vCommit = [math]::Max(2, [math]::Min(64, [int]$vCommit))
    $vRes    = [math]::Max(256, [math]::Min(4096, [int]$vRes))
    $vTotal  = [math]::Max(8, [math]::Min(512, [int]$vTotal))
    $vBlock  = [math]::Max(1, [math]::Min(32, [int]$vBlock))

    Confirm-And-Apply -Name "EXPERT CUSTOM" -Reserve ($vRes*1024) -Commit ($vCommit*1024) -Total ($vTotal*1024) -Block ($vBlock*1024)
}

function Show-Main-Menu {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "        WINDOWS MEMORY OPTIMIZER (SEGMENT HEAP)" -ForegroundColor Cyan
    Write-Host "        Developed by: METAPLAYER987" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "1. ULTIMATE GAMING (32GB+ RAM / High-End CPU)" -ForegroundColor Cyan
    Write-Host "   -> 32KiB Commit | 32KiB Threshold (Extreme)"
    Write-Host "2. OPTIMIZED STANDARD (16-32GB RAM / Mid-High CPU)" -ForegroundColor Green
    Write-Host "   -> 16KiB Commit | 32KiB Threshold (Recommended)"
    Write-Host "3. STANDARD GAMING (16GB RAM / Mid-Range CPU)" -ForegroundColor White
    Write-Host "   -> 16KiB Commit | 64KiB Threshold (Stable)"
    Write-Host "4. LITE CONFIG (4-16GB RAM / Low-End CPU)" -ForegroundColor Yellow
    Write-Host "   -> 8KiB Commit | 64KiB Threshold (Safe)"
    Write-Host "5. ACTIVATE SEGMENT HEAP (Any RAM / Factory Defaults)" -ForegroundColor Magenta
    Write-Host "   -> Global Activation (Standard)"
    Write-Host "6. EXPERT MODE (Manual Tuning)" -ForegroundColor Red
    Write-Host "----------------------------------------------------------"
    Write-Host "7. BACKUP | 8. RESTORE DEFAULTS | 9. EXIT"
}

do {
    Show-Main-Menu
    $choice = Read-Host "`nSelect Option"
    switch ($choice) {
        "1" { Confirm-And-Apply -Name "ULTIMATE" -Reserve 0x100000 -Commit 0x8000 -Total 0x8000 -Block 0x800 }
        "2" { Confirm-And-Apply -Name "OPTIMIZED STANDARD" -Reserve 0x100000 -Commit 0x4000 -Total 0x8000 -Block 0x800 }
        "3" { Confirm-And-Apply -Name "STANDARD" -Reserve 0x100000 -Commit 0x4000 -Total 0x10000 -Block 0x1000 }
        "4" { Confirm-And-Apply -Name "LITE CONFIG" -Reserve 0x100000 -Commit 0x2000 -Total 0x10000 -Block 0x1000 }
        "5" { Confirm-And-Apply -Name "FACTORY DEFAULTS" -IsDefault $true }
        "6" { Expert-Mode }
        "7" { Export-Backup; pause }
        "8" { 
            if (Test-Path $SHPath) { Remove-Item -Path $SHPath -Force }
            Write-Host "[-] System defaults restored." -ForegroundColor White; pause 
        }
        "9" { exit }
    }
} while ($true)
