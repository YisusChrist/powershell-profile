# Variables
$scoopUrl = 'https://get.scoop.sh'
$chocoUrl = 'https://community.chocolatey.org/install.ps1'
$profileUrlBase = "https://raw.githubusercontent.com/YisusChrist/powershell-profile/main"
$profileFiles = @("Microsoft.PowerShell_profile.ps1", "Aliases.ps1", "Functions.ps1")
$nerdFontRepoUrl = "https://github.com/ryanoasis/nerd-fonts"
$fontName = "CaskaydiaCove NF"
$fontFamilyName = "CascadiaCode"

# Functions

function Install-ScoopProfile {
    Write-Host "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($scoopUrl))
}

function Install-Choco {
    Write-Host "Installing Choco..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($chocoUrl))
}

function Set-Profile {
    param (
        [string[]]$urls
    )

    $documentsPath = [System.Environment]::GetFolderPath('MyDocuments')

    $profilePath = if ($PSVersionTable.PSEdition -eq "Core") {
        Join-Path -Path $documentsPath -ChildPath "PowerShell"
    }
    elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        Join-Path -Path $documentsPath -ChildPath "WindowsPowerShell"
    }

    if (!(Test-Path -Path $profilePath)) {
        New-Item -Path $profilePath -ItemType Directory
    }

    foreach ($url in $urls) {
        $fileName = [System.IO.Path]::GetFileName($url)
        $destinationPath = Join-Path -Path $profilePath -ChildPath $fileName

        if (Test-Path -Path $destinationPath) {
            Move-Item -Path $destinationPath -Destination (Join-Path -Path $profilePath -ChildPath "old_$fileName") -Force
        }

        Invoke-RestMethod -Uri $url -OutFile $destinationPath
        Write-Host "The file $fileName has been created/updated at $destinationPath."
    }

    Write-Host "Please add any persistent components to [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes."
    & (Join-Path -Path $profilePath -ChildPath "Microsoft.PowerShell_profile.ps1")
}

function Install-OhMyPosh {
    # Check if Oh-My-Posh is already installed
    if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
        Write-Host "Oh-My-Posh is already installed."
        return
    }

    Write-Host "Installing Oh-My-Posh..."
    if (Get-Command "scoop" -ErrorAction SilentlyContinue) {
        scoop install main/oh-my-posh
    }
    elseif (Get-Command "choco" -ErrorAction SilentlyContinue) {
        choco install oh-my-posh -y
    }
    elseif (Get-Command "winget" -ErrorAction SilentlyContinue) {
        winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
    }
    else {
        Write-Host "Please install Scoop, Choco, or Winget to proceed with the installation."
    }
}

function Install-Font {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families

    if ($fontFamilies -contains $fontName) {
        Write-Host "$fontName font is already installed."
        return
    }

    Write-Host "Installing $fontName font..."
    if (Get-Command "scoop" -ErrorAction SilentlyContinue) {
        try {
            scoop bucket add nerd-fonts
            scoop install nerd-fonts/$fontFamilyName-NF
        }
        catch {
            Write-Host "Could not install $fontName via Scoop. Trying Choco..."
        }
    }
    elseif (Get-Command "choco" -ErrorAction SilentlyContinue) {
        try {
            choco install nerd-fonts-$fontFamilyName -y
        }
        catch {
            Write-Host "Could not install $fontName via Choco. Trying Winget..."
        }
    }
    else {
        Install-FontManually
    }
}

function Install-FontManually {
    $releaseUrl = "$nerdFontRepoUrl/releases/latest"
    $htmlContent = Invoke-RestMethod -Uri $releaseUrl
    $regex = '<title>Release v([\d.]+) · ryanoasis/nerd-fonts · GitHub</title>'
    $latestVersion = [regex]::Match($htmlContent, $regex).Groups[1].Value
    $downloadUrl = "$nerdFontRepoUrl/releases/download/$latestVersion/$fontFamilyName.zip"

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, ".\$fontFamilyName.zip")

    Expand-Archive -Path ".\$fontFamilyName.zip" -DestinationPath ".\$fontFamilyName" -Force

    $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
    Get-ChildItem -Path ".\$fontFamilyName" -Recurse -Filter "*.ttf" | ForEach-Object {
        If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
            $destination.CopyHere($_.FullName, 0x10)
        }
    }

    Remove-Item -Path ".\$fontFamilyName" -Recurse -Force
    Remove-Item -Path ".\$fontFamilyName.zip" -Force

    Write-Host "$fontName font has been installed/updated to version $latestVersion."
}

function Install-TerminalIcons {
    Write-Host "Installing Terminal-Icons..."
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
    Install-Module -Name PSReadLine -Repository PSGallery -Force
}

# Main Script

if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    Install-ScoopProfile
}

if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
    Install-Choco
}

# Create profile with additional files
$profileUrls = $profileFiles | ForEach-Object { "$profileUrlBase/$_" }
Set-Profile -urls $profileUrls

Install-OhMyPosh

Install-Font

Install-TerminalIcons
