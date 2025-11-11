# XanAscTweaks - Development Junction Setup
# Creates directory junctions instead of copying files for instant updates

param(
    [Parameter(Mandatory=$true)]
    [string]$WoWPath,
    
    [switch]$Remove,
    
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "XanAscTweaks Development Junction Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Paths
$SourcePath = "$PSScriptRoot\XanAscTweaks"

# Handle different WoW folder structures
$InterfaceAddOnsPath = "$WoWPath\Interface\AddOns"
if (Test-Path $InterfaceAddOnsPath) {
    # Standard structure: WoW\Interface\AddOns
    $TargetPath = "$InterfaceAddOnsPath\XanAscTweaks"
    $wowAddOnsPath = $InterfaceAddOnsPath
    Write-Host "Detected: Standard WoW structure" -ForegroundColor Green
} elseif ((Get-ChildItem $WoWPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Blizzard*" -or $_.Name -like "*Titan*" -or $_.Name -like "XanAscTweaks" }).Count -gt 2) {
    # Direct AddOns folder (OneDrive symlink case)
    $TargetPath = "$WoWPath\XanAscTweaks"
    $wowAddOnsPath = $WoWPath
    Write-Host "Detected: Direct AddOns folder structure" -ForegroundColor Green
} else {
    Write-Host "ERROR: Cannot detect WoW AddOns structure!" -ForegroundColor Red
    Write-Host "Checked:" -ForegroundColor Yellow
    Write-Host "  Standard: $InterfaceAddOnsPath" -ForegroundColor Yellow
    Write-Host "  Direct:   $WoWPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "Source:  $SourcePath" -ForegroundColor Yellow
Write-Host "Target:  $TargetPath" -ForegroundColor Yellow

# Validate paths
if (-not (Test-Path $SourcePath)) {
    Write-Host "ERROR: Source path not found!" -ForegroundColor Red
    exit 1
}

if ($Remove) {
    Write-Host "`n=== REMOVING JUNCTION ===" -ForegroundColor Red
    
    if (Test-Path $TargetPath) {
        $item = Get-Item $TargetPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "Removing junction: $TargetPath" -ForegroundColor Yellow
            if (-not $DryRun) {
                Remove-Item $TargetPath -Force
                Write-Host "Junction removed successfully!" -ForegroundColor Green
            } else {
                Write-Host "[DRY RUN] Would remove junction" -ForegroundColor Gray
            }
        } else {
            Write-Host "Target exists but is not a junction - manually remove it first!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Junction does not exist" -ForegroundColor Yellow
    }
    exit 0
}

Write-Host "`n=== CREATING JUNCTION ===" -ForegroundColor Green

# Check if target already exists
if (Test-Path $TargetPath) {
    $item = Get-Item $TargetPath -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        # It's a junction - check if it points to our source
        $target = $item.Target
        if ($target -eq $SourcePath) {
            Write-Host "Junction already exists and points to correct location!" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "Junction already exists!" -ForegroundColor Yellow
            Write-Host "Junction points to: $target" -ForegroundColor Yellow
            Write-Host "Expected: $SourcePath" -ForegroundColor Yellow
            Write-Host "Removing old junction..." -ForegroundColor Yellow
            if (-not $DryRun) {
                Remove-Item $TargetPath -Force
            }
        }
    } else {
        # It's a regular folder
        Write-Host "Target folder exists (not a junction)" -ForegroundColor Yellow
        Write-Host "Removing existing folder..." -ForegroundColor Yellow
        if (-not $DryRun) {
            Remove-Item $TargetPath -Recurse -Force
        }
    }
}

# Create the junction
Write-Host "Creating junction..." -ForegroundColor Yellow
Write-Host "  Source: $SourcePath" -ForegroundColor White
Write-Host "  Target: $TargetPath" -ForegroundColor White

if (-not $DryRun) {
    New-Item -ItemType Junction -Path $TargetPath -Target $SourcePath | Out-Null
    
    # Verify it worked
    if (Test-Path "$TargetPath\XanAscTweaks.toc") {
        Write-Host "`nJunction created successfully! 🎯" -ForegroundColor Green
        Write-Host "Verification: XanAscTweaks.toc found in junction" -ForegroundColor Green
        
        Write-Host "`n✅ INSTANT DEVELOPMENT MODE ACTIVE!" -ForegroundColor Green
        Write-Host "   • File changes are immediately available in-game" -ForegroundColor Green
        Write-Host "   • No need to run deployment scripts" -ForegroundColor Green
        Write-Host "   • Just edit code and /reload in WoW" -ForegroundColor Green
    } else {
        Write-Host "`nERROR: Junction created but verification failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[DRY RUN] Would create junction" -ForegroundColor Gray
}

Write-Host "`n=== USAGE ===" -ForegroundColor Cyan
Write-Host "• Edit files in: $SourcePath" -ForegroundColor Gray
Write-Host "• Changes appear in WoW immediately" -ForegroundColor Gray
Write-Host "• Use /reload in-game to refresh addon" -ForegroundColor Gray
Write-Host "• To remove junction: .\SetupDevJunction.ps1 -WoWPath `"$WoWPath`" -Remove" -ForegroundColor Gray