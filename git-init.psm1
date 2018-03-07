function git-init {

    [CmdletBinding(
            DefaultParameterSetName='Default')]

PARAM(
[Parameter(
Mandatory=$true
,HelpMessage="Local Config Email Address."
,ParameterSetName='Default')] 
[Parameter(
Mandatory=$true
,HelpMessage="Local Config Email Address."
,ParameterSetName='InitRemote')] 
[String]$userEmail

,[Parameter(
Mandatory=$true
,HelpMessage="Local Config Name."
,ParameterSetName='Default')] 
[Parameter(
Mandatory=$true
,HelpMessage="Local Config Name."
,ParameterSetName='InitRemote')] 
[String]$userName

,[Parameter(
Mandatory=$true
,ParameterSetName='InitRemote')][String]$Remote
,[Parameter(
Mandatory=$true
,ParameterSetName='InitRemote')][String]$RemoteURL
)
    $branch = 'master'

#region initialize a new repository and its local configs
    git init
    git config user.email $userEmail
    git config user.name $userName
IF($PSCmdlet.ParameterSetName -like "InitRemote")
{
    git remote add $Remote $RemoteURL
}<#End if InitRemote#>
#endregion initialize a new repository and its local configs
    
#region global settings
    git config --global core.autocrlf true
    git config --global push.followTags true
#endregion global settings

#region commit .gitignore    
$gitignore = @'
#for specific files I want to exclude, prefix with gitignore
gitignore*.*
'@    
    New-Item -ItemType File -Name '.gitignore' -Value $gitignore
    git add .gitignore
    git commit -m "gitignore created and committed"
#endregion commit .gitignore

#region commit bootstrap, setup, and update    
$bootstrap = @'
Write-verbose -verbose "Bootstrapping missing submodules..."
git submodule update --init --recursive

'@
$setup = @'
PARAM([Switch]$SuppressBootstrap)
write-verbose "Setup (running $PsCommandPath)..." -Verbose

If (-not $SuppressBootstrap.IsPresent) {
write-verbose "Running bootstrap..." -Verbose
. .\bootstrap.ps1
}
ELSE {write-verbose "Bootstrap suppressed." -Verbose}

Get-ChildItem -Directory | Get-ChildItem -filter setup.ps1 | ForEach-Object { Push-Location; Set-Location (Split-Path -Parent $_.Fullname); . ".\$($_.Name)" -SuppressBootstrap ; Pop-Location }

write-verbose "Done ($PsCommandPath)." -Verbose

'@
$update = @'
PARAM([Switch]$Force,[Switch]$Recursive)
If(-not $Force.IsPresent) {Write-verbose -verbose "Update cancelled. Run update.ps1 -force to update submodules."}
Write-verbose -verbose "update.ps1 fetches the current commits of the submodules. THIS MAY BREAK THE MODULE and constitutes a change as far as git is concerned."
If($Force.IsPresent -and $Recursive.IsPresent) {
Write-verbose -verbose "Updating submodules recursively..."
git submodule update --recursive --remote }
ELSEIf($Force.IsPresent) {
Write-verbose -verbose "Updating submodules..."
git submodule update --remote }
'@
    New-Item -ItemType File -Name 'bootstrap.ps1' -Value $bootstrap
    New-Item -ItemType File -Name 'setup.ps1' -Value $setup
    New-Item -ItemType File -Name 'update.ps1' -Value $update
    git add bootstrap.ps1
    git add setup.ps1
    git add update.ps1
    git commit -m "bootstrap, setup, and update created and committed"
#endregion commit bootstrap, setup, and update    



}<#End git-init#>

Export-ModuleMember -Function "git-init"
