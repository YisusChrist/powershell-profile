# Scoop Install
#
if (!Get-Command "scoop" -ErrorAction SilentlyContinue) {
    Write-Host "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -scope CurrentUser
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh'))
}

# Choco install
#
if (!Get-Command "choco" -ErrorAction SilentlyContinue) {
    Write-Host "Installing Choco..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Create $PROFILE
#
# If the file does not exist, create it.
$url = "https://raw.githubusercontent.com/YisusChrist/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect PowerShell Edition & Create Profile directories if not exist
        $profilePath = if ($PSVersionTable.PSEdition -eq "Core") {
            "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType Directory
        }

        Invoke-RestMethod $url -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
        Write-Host "if you want to add any persistent components, please do so at
        [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes."
    }
    catch {
        throw $_.Exception.Message
    }
}
# If the file already exists, show the message and do nothing.
else {
    Get-Item -Path $PROFILE | Move-Item -Destination oldprofile.ps1 -Force
    Invoke-RestMethod $url -OutFile $PROFILE
    Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
    Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes."
}
& $profile

# OMP Install
#
# Check for Scoop
if (Get-Command "scoop" -ErrorAction SilentlyContinue) {
    scoop install main/oh-my-posh
}
# Check for Choco
elseif (Get-Command "choco" -ErrorAction SilentlyContinue) {
    choco install oh-my-posh -y
}
# Check for Winget
elseif (Get-Command "winget" -ErrorAction SilentlyContinue) {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
else {
    Write-Host "Please install Scoop, Choco, or Winget to proceed with the installation."
}

# Font Install
#
# Get all installed font families
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families

# Check if CaskaydiaCove NF is installed
if ($fontFamilies -notcontains "CaskaydiaCove NF") {
    # Attempt installation using Scoop
    if (Get-Command "scoop" -ErrorAction SilentlyContinue) {
        try {
            scoop bucket add nerd-fonts
            scoop install nerd-fonts/CascadiaCode-NF
        }
        catch {
            Write-Host "Could not install CaskaydiaCove NF via Scoop. Trying Choco..."
        }
    }
    # If Scoop is not available, attempt installation using Choco
    elseif (Get-Command "choco" -ErrorAction SilentlyContinue) {
        try {
            choco install nerd-fonts-cascadiacode -y
        }
        catch {
            Write-Host "Could not install CaskaydiaCove NF via Choco. Trying Winget..."
        }
    }
    # If both Scoop and Choco are not available, use the original method
    else {
        # Download and install CaskaydiaCove NF
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip", ".\CascadiaCode.zip")

        Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode" -Force
        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path ".\CascadiaCode" -Recurse -Filter "*.ttf" | ForEach-Object {
            If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        # Clean up
        Remove-Item -Path ".\CascadiaCode" -Recurse -Force
        Remove-Item -Path ".\CascadiaCode.zip" -Force
    }
}


# Terminal Icons Install
#
Install-Module -Name Terminal-Icons -Repository PSGallery -Force
Install-Module -Name PSReadLine -Repository PSGallery -Force