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

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin

# Remove PowerShell alias for curl (Invoke-WebRequest) so that we can use the
# curl alias for the actual curl executable (https://curl.se/windows)
if ((Test-Path alias:curl) -and (Test-CommandExists curl)) {
    Remove-Item alias:curl
}
# Remove PowerShell alias for wget (Invoke-WebRequest) so that we can use the
# wget alias for the actual wget executable (https://eternallybored.org/misc/wget)
if ((Test-Path alias:wget) -and (Test-CommandExists wget)) {
    Remove-Item alias:wget
}
# Replace the PowerShell alias for where with which (https://gnuwin32.sourceforge.net/packages/which.htm)
if ((Test-Path alias:where) -and (Test-CommandExists which)) {
    Remove-Item alias:where -Force
    Set-Alias -Name where -Value which
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
# Replace the PowerShell alias for rm with recycle-bin (https://github.com/sindresorhus/recycle-bin)
if ((Test-Path alias:rm) -and (Test-CommandExists recycle-bin)) {
    Remove-Item alias:rm
    Set-Alias -Name rm -Value recycle-bin
}