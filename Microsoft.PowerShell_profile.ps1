# Oh-My-Posh (https://ohmyposh.dev)
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\night-owl.omp.json" | Invoke-Expression

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`. Be aware that if you are missing
# these lines from your profile, tab completion for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Enable PowerShell Readline module
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

# Enable tab completion for scoop (https://github.com/Moeologist/scoop-completion)
Import-Module scoop-completion

# Enable Fast Scoop Search (https://github.com/shilangyu/scoop-search)
#Invoke-Expression (&scoop-search --hook)

# Enable Stupid Fast Scoop Utils (https://github.com/jewlexx/sfsu)
Invoke-Expression (&sfsu hook)

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

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin

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
    try { if (Get-Command $command) { RETURN $true } }
    Catch { Write-Host "$command does not exist"; RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

function lsd_custom { lsd --group-directories-first $args }
function ll { lsd_custom -l }
function la { lsd_custom -A }
function lla { lsd_custom -Al }
function lt { lsd_custom --tree }
function l. { lsd_custom -ald .* }

function instaloader_custom { instaloader --login=__pole_399188__ --no-profile-pic --no-metadata-json --no-compress-json --no-captions --filename-pattern="{filename}" --highlights --no-video-thumbnails --sanitize-paths $args }

function req2toml { poetry add $( Get-Content requirements.txt ) }
function py2toml {
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

function restart-profile {
    & $profile
}
function find-file($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        $place_path = $_.directory
        Write-Output "${place_path}\${_}"
    }
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

#
# Aliases
#
# If your favorite editor is not here, add an elseif and ensure that the directory it is installed in exists in your $env:Path
#
if (Test-CommandExists nvim) {
    $EDITOR = 'nvim'
}
elseif (Test-CommandExists pvim) {
    $EDITOR = 'pvim'
}
elseif (Test-CommandExists vim) {
    $EDITOR = 'vim'
}
elseif (Test-CommandExists vi) {
    $EDITOR = 'vi'
}
elseif (Test-CommandExists code) {
    $EDITOR = 'code'
}
elseif (Test-CommandExists notepad) {
    $EDITOR = 'notepad'
}
elseif (Test-CommandExists notepad++) {
    $EDITOR = 'notepad++'
}
elseif (Test-CommandExists sublime_text) {
    $EDITOR = 'sublime_text'
}
Set-Alias -Name vim -Value $EDITOR

# Remove PowerShell alias for curl (Invoke-WebRequest) so that we can use the
# curl alias for the actual curl executable (https://curl.se/windows)
if ((Test-Path alias:curl) -and (Test-CommandExists curl)) {
    Remove-Item alias:curl
}
# Replace the PowerShell alias for cd with zoxide
if ((Test-Path alias:cd) -and (Test-CommandExists z)) {
    Remove-Item alias:cd
    Set-Alias -Name cd -Value z
}
# Replace the PowerShell alias for ls with lsd
if ((Test-Path alias:ls) -and (Test-CommandExists lsd)) {
    Remove-Item alias:ls
    Set-Alias -Name ls -Value lsd_custom -Option AllScope
}
# Replace the PowerShell alias for cat with bat
if ((Test-Path alias:cat) -and (Test-CommandExists bat)) {
    Remove-Item alias:cat
    Set-Alias -Name cat -Value bat
}

winfetch
