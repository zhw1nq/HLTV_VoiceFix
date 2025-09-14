# CounterStrikeSharp Update Script
# Manually check and update CS# to latest version

param(
    [switch]$CheckOnly,
    [switch]$UpdateToLatest,
    [string]$TargetVersion,
    [switch]$Force,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
CounterStrikeSharp Update Script

Usage:
  .\update-cs.ps1 -CheckOnly                     # Only check for updates
  .\update-cs.ps1 -UpdateToLatest                # Update to latest version
  .\update-cs.ps1 -TargetVersion "1.0.150"      # Update to specific version
  .\update-cs.ps1 -Force                        # Force update even if same version

Examples:
  .\update-cs.ps1 -CheckOnly                     # Check what's available
  .\update-cs.ps1 -UpdateToLatest                # Auto-update to newest
  .\update-cs.ps1 -TargetVersion "1.0.148"      # Update to v1.0.148
"@
    exit 0
}

$ProjectFile = "HLTV_VoiceFix.csproj"
$CSPackageName = "CounterStrikeSharp.API"
$CSGitHubRepo = "roflmuffin/CounterStrikeSharp"

Write-Host "🔍 CounterStrikeSharp Update Checker" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

function Get-CurrentCSVersion {
    if (-not (Test-Path $ProjectFile)) {
        Write-Warning "Project file not found: $ProjectFile"
        return $null
    }
    
    $content = Get-Content $ProjectFile -Raw
    
    # Try different patterns to find CS# version
    $patterns = @(
        'CounterStrikeSharp[^"]*"\s+Version="([^"]*)"',
        '<PackageReference\s+Include="CounterStrikeSharp[^"]*"\s+Version="([^"]*)"',
        'CounterStrikeSharp.*?Version="([^"]*)"'
    )
    
    foreach ($pattern in $patterns) {
        if ($content -match $pattern) {
            return $matches[1]
        }
    }
    
    Write-Warning "Could not find CounterStrikeSharp version in project file"
    return $null
}

function Get-LatestCSVersion {
    param([switch]$IncludePrerelease)
    
    Write-Host "📡 Checking latest CounterStrikeSharp version..." -ForegroundColor Yellow
    
    try {
        # Method 1: GitHub Releases API
        $githubReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/$CSGitHubRepo/releases" -ErrorAction SilentlyContinue
        if ($githubReleases -and $githubReleases.Count -gt 0) {
            $latestRelease = $githubReleases[0]
            $githubVersion = $latestRelease.tag_name -replace '^v', ''
            Write-Host "📦 GitHub latest: $githubVersion" -ForegroundColor Green
            
            return @{
                Version = $githubVersion
                Source = "GitHub"
                ReleaseNotes = $latestRelease.body
                PublishDate = $latestRelease.published_at
                HtmlUrl = $latestRelease.html_url
            }
        }
    }
    catch {
        Write-Warning "Could not fetch from GitHub: $_"
    }
    
    try {
        # Method 2: NuGet API  
        $nugetIndex = Invoke-RestMethod -Uri "https://api.nuget.org/v3-flatcontainer/$CSPackageName/index.json" -ErrorAction SilentlyContinue
        if ($nugetIndex -and $nugetIndex.versions) {
            $nugetVersion = $nugetIndex.versions[-1]  # Last version
            Write-Host "📦 NuGet latest: $nugetVersion" -ForegroundColor Green
            
            return @{
                Version = $nugetVersion
                Source = "NuGet"
                ReleaseNotes = "Check NuGet page for details"
                PublishDate = "Unknown"
                HtmlUrl = "https://www.nuget.org/packages/$CSPackageName/$nugetVersion"
            }
        }
    }
    catch {
        Write-Warning "Could not fetch from NuGet: $_"
    }
    
    Write-Error "Could not determine latest CounterStrikeSharp version"
    return $null
}

function Compare-Versions {
    param($Current, $Latest)
    
    if (-not $Current -or -not $Latest) {
        return "unknown"
    }
    
    # Simple version comparison
    $currentParts = $Current.Split('.') | ForEach-Object { [int]$_ }
    $latestParts = $Latest.Split('.') | ForEach-Object { [int]$_ }
    
    for ($i = 0; $i -lt [Math]::Max($currentParts.Length, $latestParts.Length); $i++) {
        $currentPart = if ($i -lt $currentParts.Length) { $currentParts[$i] } else { 0 }
        $latestPart = if ($i -lt $latestParts.Length) { $latestParts[$i] } else { 0 }
        
        if ($latestPart -gt $currentPart) {
            return "newer"
        }
        elseif ($latestPart -lt $currentPart) {
            return "older"
        }
    }
    
    return "same"
}

function Update-CSVersion {
    param($NewVersion)
    
    Write-Host "📝 Updating CounterStrikeSharp to v$NewVersion..." -ForegroundColor Yellow
    
    if (-not (Test-Path $ProjectFile)) {
        Write-Error "Project file not found: $ProjectFile"
        return $false
    }
}

function Show-UpdateSummary {
    param($Current, $Latest, $UpdateInfo)
    
    Write-Host ""
    Write-Host "📊 Update Summary" -ForegroundColor Magenta
    Write-Host "=================" -ForegroundColor Magenta
    Write-Host "Current version: $Current" -ForegroundColor Blue
    Write-Host "Latest version:  $($Latest.Version)" -ForegroundColor Green
    Write-Host "Source:          $($Latest.Source)" -ForegroundColor Yellow
    Write-Host "Release URL:     $($Latest.HtmlUrl)" -ForegroundColor Cyan
    
    if ($Latest.ReleaseNotes -and $Latest.ReleaseNotes.Length -gt 0) {
        Write-Host ""
        Write-Host "📝 Release Notes:" -ForegroundColor Yellow
        $notes = $Latest.ReleaseNotes -split "`n" | Select-Object -First 10
        foreach ($line in $notes) {
            if ($line.Trim()) {
                Write-Host "   $line" -ForegroundColor White
            }
        }
        if ($Latest.ReleaseNotes -split "`n" | Measure-Object | Select-Object -ExpandProperty Count -gt 10) {
            Write-Host "   ... (truncated)" -ForegroundColor Gray
        }
    }
}

# Main Script Logic
try {
    # Get current version
    $currentVersion = Get-CurrentCSVersion
    if ($currentVersion) {
        Write-Host "📋 Current CS# version: $currentVersion" -ForegroundColor Blue
    } else {
        Write-Host "⚠️ Could not detect current CS# version" -ForegroundColor Yellow
        if (-not $Force) {
            $currentVersion = "unknown"
        }
    }
    
    # Get latest version info
    $latestInfo = Get-LatestCSVersion
    if (-not $latestInfo) {
        Write-Error "Could not fetch latest version information"
        exit 1
    }
    
    $latestVersion = $latestInfo.Version
    Write-Host "📦 Latest CS# version: $latestVersion" -ForegroundColor Green
    
    # Compare versions
    $comparison = Compare-Versions $currentVersion $latestVersion
    
    Write-Host ""
    switch ($comparison) {
        "newer" {
            Write-Host "🆕 Update available: $currentVersion → $latestVersion" -ForegroundColor Green
        }
        "same" {
            Write-Host "✅ You're already on the latest version: $currentVersion" -ForegroundColor Green
            if (-not $Force -and -not $TargetVersion) {
                Show-UpdateSummary $currentVersion $latestInfo
                Write-Host "Use -Force to reinstall the same version" -ForegroundColor Yellow
                exit 0
            }
        }
        "older" {
            Write-Host "⚠️ Your version is newer than the latest release: $currentVersion > $latestVersion" -ForegroundColor Yellow
            Write-Host "You might be on a prerelease version" -ForegroundColor Yellow
        }
        "unknown" {
            Write-Host "❓ Could not compare versions" -ForegroundColor Yellow
        }
    }
    
    # Determine target version
    $targetVersion = $latestVersion
    if ($TargetVersion) {
        $targetVersion = $TargetVersion
        Write-Host "🎯 Target version set to: $targetVersion" -ForegroundColor Magenta
    }
    
    # Show summary
    Show-UpdateSummary $currentVersion $latestInfo
    
    # Exit if check-only mode
    if ($CheckOnly) {
        Write-Host ""
        Write-Host "✋ Check-only mode - no changes made" -ForegroundColor Yellow
        
        if ($comparison -eq "newer" -or $Force) {
            Write-Host ""
            Write-Host "💡 To update, run:" -ForegroundColor Cyan
            Write-Host "   .\update-cs.ps1 -UpdateToLatest" -ForegroundColor White
            Write-Host "   .\update-cs.ps1 -TargetVersion `"$targetVersion`"" -ForegroundColor White
        }
        exit 0
    }
    
    # Confirm update
    if (-not $UpdateToLatest -and -not $TargetVersion -and -not $Force) {
        Write-Host ""
        Write-Host "🤔 What would you like to do?" -ForegroundColor Yellow
        Write-Host "1. Update to latest version ($latestVersion)"
        Write-Host "2. Specify custom version"
        Write-Host "3. Cancel"
        
        $choice = Read-Host "Choose (1-3)"
        
        switch ($choice) {
            "1" { $UpdateToLatest = $true }
            "2" { 
                $TargetVersion = Read-Host "Enter target version (e.g., 1.0.150)"
                $targetVersion = $TargetVersion
            }
            "3" { 
                Write-Host "Update cancelled" -ForegroundColor Yellow
                exit 0 
            }
            default { 
                Write-Host "Invalid choice, cancelling" -ForegroundColor Red
                exit 1 
            }
        }
    }
    
    # Final confirmation
    Write-Host ""
    Write-Host "🚀 Ready to update CounterStrikeSharp" -ForegroundColor Cyan
    Write-Host "   From: $currentVersion" -ForegroundColor Blue
    Write-Host "   To:   $targetVersion" -ForegroundColor Green
    Write-Host ""
    
    if (-not $Force) {
        $confirm = Read-Host "Continue with update? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Update cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Perform update
    Write-Host ""
    Write-Host "🔄 Starting update process..." -ForegroundColor Cyan
    
    $updateSuccess = Update-CSVersion $targetVersion
    
    if ($updateSuccess) {
        Write-Host ""
        Write-Host "🎉 CounterStrikeSharp successfully updated to v$targetVersion!" -ForegroundColor Green
        
        # Clean up backup
        if (Test-Path "$ProjectFile.backup") {
            Remove-Item "$ProjectFile.backup" -Force
        }
        
        Write-Host ""
        Write-Host "📋 Next steps:" -ForegroundColor Yellow
        Write-Host "   1. Test your plugin with the new CS# version" -ForegroundColor White
        Write-Host "   2. Check for any breaking changes in the release notes" -ForegroundColor White
        Write-Host "   3. Update your code if necessary" -ForegroundColor White
        Write-Host "   4. Create a new release of your plugin" -ForegroundColor White
        
        # Show release info
        if ($latestInfo.HtmlUrl) {
            Write-Host ""
            Write-Host "🔗 Release information:" -ForegroundColor Cyan
            Write-Host "   $($latestInfo.HtmlUrl)" -ForegroundColor Blue
        }
        
    } else {
        Write-Host ""
        Write-Host "❌ Update failed!" -ForegroundColor Red
        Write-Host "   Check the error messages above for details" -ForegroundColor Yellow
        Write-Host "   Your project has been restored to the previous state" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host ""
    Write-Host "💥 Script error: $_" -ForegroundColor Red
    Write-Host "   Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    
    # Attempt to restore backup
    if (Test-Path "$ProjectFile.backup") {
        Write-Host "🔄 Attempting to restore backup..." -ForegroundColor Yellow
        Copy-Item "$ProjectFile.backup" $ProjectFile -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}
    
    # Backup project file
    Copy-Item $ProjectFile "$ProjectFile.backup"
    Write-Host "💾 Backed up project file to $ProjectFile.backup" -ForegroundColor Blue
    
    try {
        # Method 1: Use dotnet CLI (most reliable)
        Write-Host "Using dotnet CLI to update package..." -ForegroundColor Yellow
        
        # Remove existing package
        $removeOutput = dotnet remove package $CSPackageName 2>&1
        
        # Add new version
        $addOutput = dotnet add package $CSPackageName --version $NewVersion 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Updated via dotnet CLI" -ForegroundColor Green
        }
        else {
            Write-Warning "dotnet CLI update failed, trying manual method..."
            
            # Method 2: Manual file replacement
            $content = Get-Content $ProjectFile -Raw
            $patterns = @(
                '(CounterStrikeSharp[^"]*"\s+Version=")[^"]*(")',
                '(<PackageReference\s+Include="CounterStrikeSharp[^"]*"\s+Version=")[^"]*(")'
            )
            
            $updated = $false
            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    $content = $content -replace $pattern, "`${1}$NewVersion`$2"
                    $updated = $true
                    break
                }
            }
            
            if ($updated) {
                Set-Content $ProjectFile -Value $content -NoNewline
                Write-Host "✅ Updated via manual replacement" -ForegroundColor Green
            }
            else {
                Write-Error "Could not update project file"
                return $false
            }
        }
        
        # Test restore
        Write-Host "🔧 Testing package restore..." -ForegroundColor Yellow
        $restoreOutput = dotnet restore 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Package restore successful" -ForegroundColor Green
        }
        else {
            Write-Warning "Package restore had warnings:"
            Write-Host $restoreOutput -ForegroundColor Yellow
        }
        
        # Test build
        Write-Host "🏗️ Testing build..." -ForegroundColor Yellow
        $buildOutput = dotnet build $ProjectFile -c Release --verbosity quiet 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Build successful with CS# v$NewVersion" -ForegroundColor Green
        }
        else {
            Write-Error "Build failed with CS# v$NewVersion"
            Write-Host $buildOutput -ForegroundColor Red
            
            # Restore backup
            Write-Host "🔄 Restoring backup..." -ForegroundColor Yellow
            Copy-Item "$ProjectFile.backup" $ProjectFile -Force
            dotnet restore | Out-Null
            
            return $false
        }
        
        return $true
    }
    catch {
        Write-Error "Update failed: $_"
        
        # Restore backup
        if (Test-Path "$ProjectFile.backup") {
            Copy-Item "$ProjectFile.backup" $ProjectFile -Force
            dotnet restore | Out-Null
        }
        
        return $false