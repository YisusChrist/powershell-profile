# Get the directory of the current $PROFILE script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. $scriptDir\Functions.ps1
. $scriptDir\Aliases.ps1

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

# Set the CommandNotFoundAction to automatically call Install-OrSearchScoop
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param([System.Management.Automation.CommandNotFoundException]$cmdNotFound)

    # Check if the command name starts with "get-" or ".\"
    if ($cmdNotFound.Message -notlike "get-*" -and $cmdNotFound.Message -notlike ".\*") {
        # Call Install-OrSearchScoop with the unrecognized command
        Install-OrSearchScoop -command $cmdNotFound.Message
    }
}

winfetch
