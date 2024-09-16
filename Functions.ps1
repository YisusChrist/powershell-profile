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

function instaloader_custom {
    instaloader `
        --login=__pole_399188__ `
        --no-profile-pic `
        --no-metadata-json `
        --no-compress-json `
        --no-captions `
        --filename-pattern="{filename}" `
        --highlights `
        --no-video-thumbnails `
        --sanitize-paths `
        $args
}

function instagram_dl {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$user,

        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [string[]]$users
    )

    begin {
        $allUsers = @()
    }

    process {
        if ($null -ne $user) {
            $allUsers += $user
        }
        if ($null -ne $users) {
            $allUsers += $users
        }
    }

    end {
        Write-Output "Downloading media for the following users: $allUsers"
        
        foreach ($username in $allUsers) {
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

<#
.SYNOPSIS
Executes a command periodically and displays the output

.PARAMETERS
-n, --interval <seconds>   Specify update interval (default: 2 seconds)
-d, --differences          Highlight differences between updates
-g, --chgexit              Exit when the output changes
-t, --no-title             Don't show the header
-b, --beep                 Beep if the command has an error
-p, --precise              Attempt to run command at exact intervals
-e, --errexit              Exit on command error
-c, --color                Interpret ANSI color sequences
-x, --exec                 Pass the command to exec
-w, --no-linewrap          Disable line wrapping
-h, --help                 Display this help and exit
-v, --version              Output version information and exit
.LINK
https://github.com/YisusChrist/watch-powershell
#>
function watch {
    Param (
        [string[]]$Args
    )

    $interval = 2
    $differences = $false
    $chgexit = $false
    $noTitle = $false
    $beep = $false
    $precise = $false
    $errexit = $false
    $color = $false
    $exec = $false
    $noLinewrap = $false
    $help = $false
    $version = $false
    $command = @()

    Write-Host "watch: $Args"

    for ($i = 0; $i -lt $Args.Length; $i++) {
        Write-Host "$i Arg: $($Args[$i])"
        switch ($Args[$i]) {
            '-n' {
                $interval = [int]$Args[++$i]
            }
            '--interval' {
                $interval = [int]$Args[++$i]
            }
            '-d' { $differences = $true }
            '--differences' { $differences = $true }
            '-g' { $chgexit = $true }
            '--chgexit' { $chgexit = $true }
            '-t' { $noTitle = $true }
            '--no-title' { $noTitle = $true }
            '-b' { $beep = $true }
            '--beep' { $beep = $true }
            '-p' { $precise = $true }
            '--precise' { $precise = $true }
            '-e' { $errexit = $true }
            '--errexit' { $errexit = $true }
            '-c' { $color = $true }
            '--color' { $color = $true }
            '-x' { $exec = $true }
            '--exec' { $exec = $true }
            '-w' { $noLinewrap = $true }
            '--no-linewrap' { $noLinewrap = $true }
            '-h' { $help = $true }
            '--help' { $help = $true }
            '-v' { $version = $true }
            '--version' { $version = $true }
            default {
                # Collect all remaining arguments as the command
                $command += $Args[$i]
            }
        }
    }

    # Extract the comamnd arguments
    $commandString = $command -join " "

    for ($i = 0; $i -lt $command.Length; $i++) {
        if ($command[$i] -eq "'") {
            $command = $command -replace "'", "''"
        }
    }

    if ($Help) {
        Write-Host "Usage: " -NoNewline
        Write-Host "watch" -ForegroundColor Green
        Write-Host "Options:"
        Write-Host "  -n, --interval <seconds>   " -ForegroundColor Cyan -NoNewline
        Write-Host "Specify update interval (default: 2 seconds)"
        Write-Host "  -d, --differences          " -ForegroundColor Cyan -NoNewline
        Write-Host "Highlight differences between updates"
        Write-Host "  -g, --chgexit              " -ForegroundColor Cyan -NoNewline
        Write-Host "Exit when the output changes"
        Write-Host "  -t, --no-title             " -ForegroundColor Cyan -NoNewline
        Write-Host "Don't show the header"
        Write-Host "  -b, --beep                 " -ForegroundColor Cyan -NoNewline
        Write-Host "Beep if the command has an error"
        Write-Host "  -p, --precise              " -ForegroundColor Cyan -NoNewline
        Write-Host "Attempt to run command at exact intervals"
        Write-Host "  -e, --errexit              " -ForegroundColor Cyan -NoNewline
        Write-Host "Exit on command error"
        Write-Host "  -c, --color                " -ForegroundColor Cyan -NoNewline
        Write-Host "Interpret ANSI color sequences"
        Write-Host "  -x, --exec                 " -ForegroundColor Cyan -NoNewline
        Write-Host "Pass the command to exec"
        Write-Host "  -w, --no-linewrap          " -ForegroundColor Cyan -NoNewline
        Write-Host "Disable line wrapping"
        Write-Host "  -h, --help                 " -ForegroundColor Cyan -NoNewline
        Write-Host "Display this help and exit"
        Write-Host "  -v, --version              " -ForegroundColor Cyan -NoNewline
        Write-Host "Output version information and exit"
        return
    }

    if ($Version) {
        Write-Host "watch " -ForegroundColor Green -NoNewline
        Write-Host "1.0"
        Write-Host "Written by YisusChrist" -ForegroundColor Cyan
        return
    }

    $previousOutput = ""
    $runTime = Get-Date

    while ($true) {
        $output = & $commandString
        $exitCode = $LASTEXITCODE

        if ($chgexit -and $previousOutput -ne "" -and $previousOutput -ne $output) {
            break
        }

        if ($errexit -and $exitCode -ne 0) {
            Write-Host "Command exited with error code $exitCode. Press any key to exit."
            [void][System.Console]::ReadKey($true)
            break
        }

        if ($noTitle -eq $false) {
            Clear-Host
            $currentTime = Get-Date
            Write-Host "Every $interval s: $command"
            Write-Host "Current time: $currentTime"
            Write-Host ""
        }

        if ($differences -and $previousOutput -ne "") {
            $previousLines = $previousOutput -split "`n"
            $currentLines = $output -split "`n"
            for ($i = 0; $i -lt [Math]::Max($previousLines.Count, $currentLines.Count); $i++) {
                if ($i -ge $previousLines.Count -or $i -ge $currentLines.Count -or $previousLines[$i] -ne $currentLines[$i]) {
                    Write-Host "$($currentLines[$i])" -ForegroundColor Red
                } else {
                    Write-Host "$($currentLines[$i])"
                }
            }
        } else {
            Write-Output "$output"
        }

        $previousOutput = $output

        if ($beep -and $exitCode -ne 0) {
            [console]::beep(1000, 500)
        }
        
        if ($precise) {
            $runTime = $runTime.AddSeconds($interval)
            $sleepTime = $runTime.Subtract((Get-Date)).TotalMilliseconds
            if ($sleepTime -gt 0) {
                Start-Sleep -Milliseconds $sleepTime
            }
        } else {
            Start-Sleep -Seconds $interval
        }
    }
}

function remove-empty-folders {
    param (
        [Parameter(Mandatory = $true)]
        [string]$path
    )

    Write-Host "Removing empty folders in $path..."
    robocopy $path $path /S /MOVE
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

function Get-FolderSize {
    param(
        [string]$FolderPath
    )
    if (Test-Path $FolderPath) {
        $files = Get-ChildItem -Recurse -File -Path $FolderPath
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        $fileCount = $files.Count
        $totalSizeInMB = [math]::round($totalSize / 1MB, 2)

        Write-Host "Total: $fileCount files, $totalSizeInMB MiB in '$FolderPath'" -ForegroundColor Yellow
    } else {
        Write-Host "Folder '$FolderPath' does not exist." -ForegroundColor Red
    }
}

function remove_folder {
    param (
        [string]$folder
    )

    # Check if the folder exists
    if (Test-Path $folder) {
        # Remove the folder
        Remove-Item -Recurse -Force -LiteralPath $folder 2> $null
    }
    else {
        Write-Host "Folder '$folder' does not exist." -ForegroundColor Red
    }
}

function clean_temp {
    $tempFolders = @($env:TEMP, "$env:WINDIR\Temp")

    foreach ($folder in $tempFolders) {
        Write-Host "Cleaning temporary folder: '$folder'"
        Get-FolderSize -FolderPath $folder
        remove_folder $folder
        Write-Host "Folder '$folder' cleaned." -ForegroundColor Green
    }
}

function scoop_clean {
    Write-Host "Cleaning Scoop cache..."
    scoop cache
    remove_folder $env:SCOOP\cache
    scoop cleanup *
}
