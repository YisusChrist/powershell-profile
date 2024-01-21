function Test-Profile {
    try {
        $url = "https://raw.githubusercontent.com/YisusChrist/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
        return $newhash -eq $oldhash
    }
    catch {
        Write-Error "unable to check for `$profile updates"
    }
    Remove-Variable @("newhash", "oldhash", "url")
    Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1"
}

function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { Write-Host "$command does not exist"; RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

function Test-Installation {
    Param (
        [string]$target,
        [string]$type
    )

    if ($type -eq "command") {
        $targetInstalled = Test-CommandExists $target
    }
    elseif ($type -eq "font") {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families
        $targetInstalled = $fontFamilies -contains $target
    }
    elseif ($type -eq "file") {
        if ($target -eq $PROFILE) {
            $targetInstalled = Test-Profile
        }
        else {
            $targetInstalled = Test-Path -Path $target -PathType Leaf
        }       
    }
    else {
        Write-Host "Invalid type: $type"
        return $false
    }

    # Colorize the target part
    if ($type -eq "file" -and $target -eq $PROFILE) {
        $target = '$PROFILE'
    }
    Write-Host "$target " -ForegroundColor Cyan -NoNewline
    Write-Host "installation status: " -NoNewline
    # Colorize only the result part
    if ($targetInstalled) {
        Write-Host "OK" -ForegroundColor Green
    }
    else {
        Write-Host "FAIL" -ForegroundColor Red
    }

    return $targetInstalled
}

# Verify Scoop Installation
$scoopInstalled = Test-Installation -target "scoop" -type "command"

# Verify Choco Installation
$chocoInstalled = Test-Installation -target "choco" -type "command"

# Verify oh-my-posh Installation
$ohMyPoshInstalled = Test-Installation -target "oh-my-posh" -type "command"

# Verify nerd font Installation
$nerdFontInstalled = Test-Installation -target "CaskaydiaCove NF" -type "font"

# Verify PROFILE Update
$profileUpdated = Test-Installation -target $PROFILE -type "file"

# Output Summary
if ($scoopInstalled -and $chocoInstalled -and $ohMyPoshInstalled -and $nerdFontInstalled -and $profileUpdated) {
    Write-Host "`r`nAll components are installed and updated successfully." -ForegroundColor Green
}
else {
    Write-Host "`r`nVerification failed. Check the individual installation statuses above for details." -ForegroundColor Red
}
