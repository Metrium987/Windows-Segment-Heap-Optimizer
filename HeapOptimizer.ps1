<#
.SYNOPSIS
    Windows Segment Heap Optimizer - Ultimate Expert Edition v1.2.1
.DESCRIPTION
    Memory optimization tool with dynamic IFEO exclusion table.
.AUTHOR
    METAPLAYER987 / Metrium987
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- AUTO-ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- REGISTRY PATHS ---
$SMPath   = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$SHPath   = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Segment Heap"
$IFEORoot = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
$IFEOWow  = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"

# --- CORE FUNCTIONS ---

function Export-Backup {
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupName = "$PSScriptRoot\Backup_Heap_$Timestamp.reg"
    Write-Host "[-] Creating backup: $BackupName" -NoNewline
    reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" "$BackupName" /y | Out-Null
    Write-Host " [OK]" -ForegroundColor Green
}

function Get-ExcludedApps {
    $Paths = @($IFEORoot, $IFEOWow)
    $Apps = New-Object System.Collections.Generic.HashSet[string]
    foreach ($P in $Paths) {
        if (Test-Path $P) {
            Get-ChildItem -Path $P | ForEach-Object {
                $val = Get-ItemProperty -Path $_.PSPath -Name "FrontEndHeapDebugOptions" -ErrorAction SilentlyContinue
                if ($val.FrontEndHeapDebugOptions -eq 4) { $Apps.Add($_.PSChildName) | Out-Null }
            }
        }
    }
    return $Apps | Sort-Object
}

function Manage-Exclusions {
    # Initialize the list from registry
    $Apps = Get-ExcludedApps 

    do {
        Clear-Host
        Write-Host "=== APP EXCLUSION MANAGER (IFEO) ===" -ForegroundColor Cyan
        Write-Host "DESCRIPTION: Compatibility shield to fix app bugs or performance drops." -ForegroundColor Gray
        Write-Host "----------------------------------------------------------"
        Write-Host "INSTRUCTIONS:" -ForegroundColor Yellow
        Write-Host "1. Enter ONLY the executable name (e.g., chrome.exe)."
        Write-Host "2. DO NOT include the folder path."
        Write-Host "3. NOTE: Applications must be restarted for changes to take effect.`n"
        
        # TABLE DISPLAY
        Write-Host "----------------------------------------------------------"
        Write-Host "| ID  | EXCLUDED APPLICATION NAME         | STATUS      |"
        Write-Host "----------------------------------------------------------"
        if ($Apps.Count -eq 0) {
            Write-Host "| --  | No exclusions found               |    EMPTY    |"
        } else {
            $id = 1
            foreach ($A in $Apps) {
                "{0,-3} | {1,-33} | {2,-11} |" -f $id, $A, "EXCLUDED"
                $id++
            }
        }
        Write-Host "----------------------------------------------------------"
        Write-Host "`n1. Add Exclusion | 2. Remove Exclusion | 3. Back to Main Menu"
        $opt = Read-Host "Select"

        if ($opt -eq "1") {
            $raw = Read-Host ">> Enter executable name"
            $name = [System.IO.Path]::GetFileName($raw).Trim()
            if ($name -like "*.exe") {
                $Targets = @("$IFEORoot\$name", "$IFEOWow\$name")
                foreach ($T in $Targets) {
                    if (-not (Test-Path $T)) { New-Item -Path $T -Force | Out-Null }
                    Set-ItemProperty -Path $T -Name "FrontEndHeapDebugOptions" -Value 4 -Type DWord
                }
                # FORCE REFRESH
                $Apps = Get-ExcludedApps 
                Write-Host "`n[+] Successfully added: $name" -ForegroundColor Green
                Write-Host "[!] Restart the app or PC to apply." -ForegroundColor Yellow
            } else { Write-Host "ERROR: Must end with .exe" -ForegroundColor Red }
            pause
        }
        elseif ($opt -eq "2") {
            $raw = Read-Host ">> Enter name to remove"
            $name = [System.IO.Path]::GetFileName($raw).Trim()
            $Targets = @("$IFEORoot\$name", "$IFEOWow\$name")
            $found = $false
            foreach ($T in $Targets) {
                if (Test-Path $T) { 
                    Remove-ItemProperty -Path $T -Name "FrontEndHeapDebugOptions" -ErrorAction SilentlyContinue 
                    $found = $true
                }
            }
            if ($found) { 
                # FORCE REFRESH
                $Apps = Get-ExcludedApps 
                Write-Host "`n[-] Removed: $name" -ForegroundColor White 
                Write-Host "[!] Restart the app or PC to apply." -ForegroundColor Yellow
            }
            else { Write-Host "ERROR: App not found." -ForegroundColor Red }
            pause
        }
    } while ($opt -ne "3")
}

function Confirm-And-Apply {
    param($Name, $Reserve, $Commit, $Total, $Block, $IsDefault = $false)
    Clear-Host
    Write-Host "!!! PENDING MODIFICATIONS: $Name !!!" -ForegroundColor Cyan
    Export-Backup
    if ((Read-Host "`nConfirm application? (Y/N)") -eq "Y") {
        if (-not (Test-Path $SHPath)) { New-Item -Path $SHPath -Force | Out-Null }
        Set-ItemProperty -Path $SHPath -Name "Enabled" -Value 1 -Type DWord
        if (-not $IsDefault) {
            Set-ItemProperty -Path $SMPath -Name "HeapSegmentReserve" -Value $Reserve -Type DWord
            Set-ItemProperty -Path $SMPath -Name "HeapSegmentCommit" -Value $Commit -Type DWord
            Set-ItemProperty -Path $SMPath -Name "HeapDeCommitTotalFreeThreshold" -Value $Total -Type DWord
            Set-ItemProperty -Path $SMPath -Name "HeapDeCommitFreeBlockThreshold" -Value $Block -Type DWord
        } else {
            $Params = @("HeapSegmentReserve","HeapSegmentCommit","HeapDeCommitTotalFreeThreshold","HeapDeCommitFreeBlockThreshold")
            foreach ($P in $Params) { Remove-ItemProperty -Path $SMPath -Name $P -ErrorAction SilentlyContinue }
        }
        Write-Host "Success! REBOOT REQUIRED." -ForegroundColor Green; pause
    }
}

# --- MAIN UI ---
do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "    WINDOWS SEGMENT HEAP OPTIMIZER v1.2.1 - EXPERT EDITION" -ForegroundColor Cyan
    Write-Host "    Dev: METAPLAYER987" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    Write-Host "1. ULTIMATE GAMING (32GB+ RAM / High-End CPU)" -ForegroundColor Green
    Write-Host "    -> 32KiB Commit | 32KiB Threshold (Extreme)"
    
    Write-Host "2. OPTIMIZED STANDARD (16-32GB RAM / Mid-High CPU)" -ForegroundColor Green
    Write-Host "    -> 16KiB Commit | 32KiB Threshold (Recommended)"
    
    Write-Host "3. STANDARD GAMING (16GB RAM / Mid-Range CPU)" -ForegroundColor Yellow
    Write-Host "    -> 16KiB Commit | 64KiB Threshold (Stable)"
    
    Write-Host "4. LITE CONFIG (4-16GB RAM / Low-End CPU)" -ForegroundColor Yellow
    Write-Host "    -> 8KiB Commit | 64KiB Threshold (Safe)"
    
    Write-Host "5. ACTIVATE SEGMENT HEAP (Any RAM / Factory Defaults)" -ForegroundColor White
    Write-Host "    -> Global Activation (Standard)"
    
    Write-Host "6. EXPERT MODE (Manual Tuning)" -ForegroundColor Red
    Write-Host "    -> Full manual control"
    
    Write-Host "----------------------------------------------------------"
    Write-Host "7. APP EXCLUSION MANAGER (IFEO Table)" -ForegroundColor Magenta
    Write-Host "8. RESTORE FACTORY DEFAULTS" -ForegroundColor Gray
    Write-Host "9. EXIT"
    
    $choice = Read-Host "`nSelect Option"
    switch ($choice) {
        "1" { Confirm-And-Apply -Name "ULTIMATE" -Reserve 0x100000 -Commit 0x8000 -Total 0x8000 -Block 0x800 }
        "2" { Confirm-And-Apply -Name "OPTIMIZED STANDARD" -Reserve 0x100000 -Commit 0x4000 -Total 0x8000 -Block 0x800 }
        "3" { Confirm-And-Apply -Name "STANDARD" -Reserve 0x100000 -Commit 0x4000 -Total 0x10000 -Block 0x1000 }
        "4" { Confirm-And-Apply -Name "LITE" -Reserve 0x100000 -Commit 0x2000 -Total 0x10000 -Block 0x1000 }
        "5" { Confirm-And-Apply -Name "FACTORY DEFAULTS" -IsDefault $true }
        "7" { Manage-Exclusions }
        "8" { Export-Backup; if (Test-Path $SHPath) { Remove-Item -Path $SHPath -Force }; pause }
        "9" { exit }
    }
} while ($true)
