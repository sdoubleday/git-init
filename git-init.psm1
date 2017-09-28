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


}<#End git-init#>

Export-ModuleMember -Function "git-init"
