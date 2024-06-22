#
# Aliases
#

# Function to set/replace an alias if the command exists
function Set-ConditionalAlias {
    param (
        [string]$command,
        [string]$aliasName,
        [string]$aliasValue = $command,
        [string]$option
    )

    # Check if the command exists
    if (Get-Command $command -ErrorAction SilentlyContinue) {
        # Remove the existing alias if it exists
        if (Test-Path "alias:$aliasName") {
            Remove-Item "alias:$aliasName" -Force
        }
        # Set the new alias
        if ($option) {
            Set-Alias -Name $aliasName -Value $aliasValue -Option $option
        }
        else {
            Set-Alias -Name $aliasName -Value $aliasValue
        }
        Write-Host "Alias '$aliasName' has been set to '$aliasValue'."
    }
    else {
        Write-Host "Command '$command' does not exist."
    }
}

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

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin

# Remove PowerShell alias for curl so that we can use the actual curl executable
Set-ConditionalAlias -command "curl" -aliasName "curl"
# Remove PowerShell alias for wget so that we can use the actual wget executable
Set-ConditionalAlias -command "wget" -aliasName "wget"
# Replace the PowerShell alias for where with which
Set-ConditionalAlias -command "which" -aliasName "where"
# Replace the PowerShell alias for cd with zoxide
Set-ConditionalAlias -command "z" -aliasName "cd" -aliasValue "z"
# Replace the PowerShell alias for ls with lsd
Set-ConditionalAlias -command "lsd" -aliasName "ls" -aliasValue "lsd_custom" -option AllScope
# Replace the PowerShell alias for cat with bat
Set-ConditionalAlias -command "bat" -aliasName "cat" -aliasValue "bat"
# Replace the PowerShell alias for rm with recycle-bin
Set-ConditionalAlias -command "recycle-bin" -aliasName "rm" -aliasValue "recycle-bin"
