#
# Functions
#
# Simple function to start a new elevated process. If arguments are supplied then 
# a single command is started with admin rights; if not then a new admin instance
# of PowerShell is started.
function admin {
    if ($args.Count -gt 0) {   
        $argList = "& '" + $args + "'"
        Start-Process "$psHome\powershell.exe" -Verb runAs -ArgumentList $argList
    }
    else {
        Start-Process "$psHome\powershell.exe" -Verb runAs
    }
}

#check for updates
function update-profile {
    try {
        $url = "https://raw.githubusercontent.com/YisusChrist/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
        if ($newhash -ne $oldhash) {
            Get-Content "$env:temp/Microsoft.PowerShell_profile.ps1" | Set-Content $PROFILE
            . $PROFILE
            return
        }
    }
    catch {
        Write-Error "unable to check for `$profile updates"
    }
    Remove-Variable @("newhash", "oldhash", "url")
    Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1"
}

# Make it easy to edit this profile once it's installed
function Edit-Profile {
    if ($host.Name -match "ise") {
        $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
    }
    else {
        code $profile.CurrentUserAllHosts
    }
}

# Useful shortcuts for traversing directories
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Compute file hashes - useful for checking successful downloads 
function md5 { Get-FileHash -Algorithm MD5 $args }
function sha1 { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Quick shortcut to start notepad
function n { notepad $args }

# Drive shortcuts
function C: { Set-Location C:\ }
function D: { Set-Location D:\ }

function Test-CommandExists {
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        if (Get-Command $command) {
            RETURN $true
        }
    }
    Catch {
        Write-Host "$command does not exist";
        RETURN $false
    }
    Finally {
        $ErrorActionPreference = $oldPreference
    }
}

function lsd_custom { lsd --group-directories-first $args }
function ll { lsd_custom -l }
function la { lsd_custom -A }
function lla { lsd_custom -Al }
function lt { lsd_custom --tree }
function l. { lsd_custom -ald .* }

function instaloader_custom { instaloader --login=__pole_399188__ --no-profile-pic --no-metadata-json --no-compress-json --no-captions --filename-pattern="{filename}" --highlights --no-video-thumbnails --sanitize-paths $args }

function instagram_dl {
    foreach ($user in $args) {
        $username = $user.Split("/")[-1]
        Write-Output "Downloading media for user: $username..."
        
        # Run instaloader_custom command
        instaloader_custom -F -s $username
        
        Write-Output "Downloading reels for user: $username..."
        
        # Define the gallery-dl command without cookies
        $galleryDlCommand = "gallery-dl https://www.instagram.com/$username/reels"

        # Run gallery-dl command without cookies    
        Invoke-Expression $galleryDlCommand
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Gallery-dl command failed for user: $username. Retrying with --cookies-from-browser brave."
            
            # Retry gallery-dl command with cookies
            $galleryDlCommandWithCookies = "$galleryDlCommand --cookies-from-browser brave"

            Invoke-Expression $galleryDlCommandWithCookies
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Gallery-dl command failed because cookies are being used by the browser. Close the browser and try again."
            }
        }
    }
}

function req2toml { poetry add $( Get-Content requirements.txt ) }
function pyreq2toml {
    poetry add pipreqs
    poetry run pipreqs .
    req2toml
    poetry remove pipreqs
    Remove-Item requirements.txt
}

function Get-PubIP {
    (Invoke-WebRequest http://ifconfig.me/ip ).Content
}
function uptime {
    #Windows Powershell only
    If ($PSVersionTable.PSVersion.Major -eq 5 ) {
        Get-WmiObject win32_operatingsystem |
        Select-Object @{EXPRESSION = { $_.ConverttoDateTime($_.lastbootuptime) } } | Format-Table -HideTableHeaders
    }
    Else {
        net statistics workstation | Select-String "since" | foreach-object { $_.ToString().Replace('Statistics since ', '') }
    }
}
function geoiplookup {
    $ip = $args[0]
    $url = "https://ipinfo.io/$ip"
    $response = Invoke-RestMethod -Uri $url
    $response
}

function restart-profile {
    & $profile
}
function find-file($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        $place_path = $_.directory
        Write-Output "${place_path}\${_}"
    }
}
function func-def($name) {
    Write-Output (Get-Command $name).Definition
}

function clist { choco list }

function e { exit }

function watch {
    Param ($command)
    # Check if the command exists
    if (-not (Test-CommandExists $command) -OR $null -eq $command) {
        Write-Error "Command '$command' does not exist"
        return
    }
    while ($true) {
        $command
        Start-Sleep -Seconds 1
        Clear-Host
    }
}

# Function to measure the time it takes to load this profile
# Source: https://github.com/IISResetMe/PSProfiler
function pprofiler { Measure-Script -Path $PROFILE -Top 5 }

function Install-OrSearchScoop {
    param ($command)

    # If not recognized, prompt the user
    $userResponse = Read-Host -Prompt "The command '$command' was not found. Do you want to search in the Scoop repository? (Y/N)"

    if ($userResponse -eq 'y' -or $userResponse -eq 'Y') {
        # Search in Scoop repository
        Write-Host "Searching in Scoop repository..."

        $searchResult = & scoop search $command

        if ($searchResult) {
            Write-Host "Package '$command' found in Scoop repository. You may consider installing it using 'scoop install $command'"
        }
        else {
            Write-Host "Package '$command' not found in Scoop repository. It may not be available via Scoop."
        }
    }
    else {
        Write-Host "User chose not to search in the Scoop repository."
    }
}