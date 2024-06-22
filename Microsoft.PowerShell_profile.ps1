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
if (Get-Command "zoxide" -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# https://github.com/PowerShell/PSReadLine/issues/2046#issuecomment-1525710944
function IsVirtualTerminalProcessingEnabled {
    $MethodDefinitions = @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
'@
    $Kernel32 = Add-Type -MemberDefinition $MethodDefinitions -Name 'Kernel32' -Namespace 'Win32' -PassThru
    $hConsoleHandle = $Kernel32::GetStdHandle(-11) # STD_OUTPUT_HANDLE
    $mode = 0
    $Kernel32::GetConsoleMode($hConsoleHandle, [ref]$mode) >$null
    if ($mode -band 0x0004) {
        # 0x0004 ENABLE_VIRTUAL_TERMINAL_PROCESSING
        return $true
    }
    return $false
}

function CanUsePredictionSource {
    return (! [System.Console]::IsOutputRedirected) -and (IsVirtualTerminalProcessingEnabled)
}

# Enable PowerShell modules
if (CanUsePredictionSource) { 
    #Import-Module -Name Terminal-Icons
    Import-Module PSReadLine
    Set-PSReadLineOption `
        -PredictionViewStyle ListView `
        -PredictionSource History `
        -HistoryNoDuplicates `
        -EditMode Windows
}

# Enable tab completion for scoop (https://github.com/Moeologist/scoop-completion)
if (Get-Module -ListAvailable -Name scoop-completion) {
    Import-Module scoop-completion
}

# Enable Fast Scoop Search (https://github.com/shilangyu/scoop-search)
#Invoke-Expression (&scoop-search --hook)

# Enable Stupid Fast Scoop Utils (https://github.com/jewlexx/sfsu)
if (Get-Command "sfsu" -ErrorAction SilentlyContinue) {
    Invoke-Expression (&sfsu hook)
}

# Check if the environment variable $HISTORY is set
if (!$env:HISTORY) {
    # If not, set the $HISTORY variable to the correct value
    $env:HISTORY = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
}

# Set the CommandNotFoundAction to automatically call Install-OrSearchScoop
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param([System.Management.Automation.CommandNotFoundException]$cmdNotFound)

    # Check if the command name starts with "get-" or ".\"
    if ($cmdNotFound.Message -notlike "get-*" -and $cmdNotFound.Message -notlike ".\*") {
        # Call Install-OrSearchScoop with the unrecognized command
        Install-OrSearchScoop -command $cmdNotFound.Message
    }
}

if (Get-Command "winfetch") {
    winfetch
}

# Get the directory of the current $PROFILE script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. $scriptDir\Functions.ps1
. $scriptDir\Aliases.ps1
