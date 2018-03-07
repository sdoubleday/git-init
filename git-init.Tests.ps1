<#SDS Modified Pester Test file header to handle modules.#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = ( (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.' ) -replace '.ps1', '.psd1'
$scriptBody = "using module $here\$sut"
$script = [ScriptBlock]::Create($scriptBody)
. $script


<#
per documentation: You can also check what Git thinks a specific key's value is by typing git config <key>

user.name
user.email
core.editor
core.autocrlf -eq true (should also be set globally: git config --global core.autocrlf true
#>

<#before each, create a directory. after each, delete it.#>

Describe "git-init" {

    BeforeEach{
        Push-Location
        $workingFile = New-TemporaryFile
        $dir = New-Item -ItemType Directory -Path "$($workingFile.Directory.FullName)\$($workingFile.basename)"
        Set-Location $dir
    }<#End BeforeEach#>
    AfterEach{
        Pop-Location
        Remove-Item $workingFile -Force
        Remove-item $dir -Recurse -Force
        
    }<#End AfterEach#>

    It "git config user.email should be 'test@gmail.com' (local)" {
        git-init -userEmail 'test@gmail.com' -userName 'test'
        git config user.email | Should Be 'test@gmail.com'
    }

    It "git config user.name should be 'test'" {
        git-init -userEmail 'test@gmail.com' -userName 'test'
        git config user.name | Should Be 'test'
    }


    It "git config remote.origin.url should be https://github.com/test/test.git" {
        git-init -userEmail 'test@gmail.com' -userName 'test' -Remote origin  -RemoteURL https://github.com/test/test.git
        git config remote.origin.url | Should Be 'https://github.com/test/test.git'
    }

    It "git config core.autocrlf should be 'true'" {
        git-init -userEmail 'test@gmail.com' -userName 'test'
            git config core.autocrlf | Should Be 'true'
    }

    It "git config push.followTags should be 'true'" {
        git-init -userEmail 'test@gmail.com' -userName 'test'
            git config push.followTags | Should Be 'true'
    }

    It "A commit has been completed" {
        git-init -userEmail 'test@gmail.com' -userName 'test' -Remote origin  -RemoteURL https://github.com/test/test.git
        @( foreach ($i in (git log --oneline) ) {$i.Remove(0,8)} ) -like "gitignore created and committed" | Should Be 'gitignore created and committed'
    }

    <#This is actually accomplished by the first commit.#>
    It "master branch has been created and is the HEAD branch" {
        git-init -userEmail 'test@gmail.com' -userName 'test' -Remote origin  -RemoteURL https://github.com/test/test.git
        @(git branch) -like '* master' | Should Be '* master'
    }

    It ".gitignore is created and contains an exclusion for gitignore*.*" {
        git-init -userEmail 'test@gmail.com' -userName 'test'
        $output = @'
#for specific files I want to exclude, prefix with gitignore
gitignore*.*

'@
        get-childitem .gitignore | get-content | Out-String | Should Be $output
    }

    It "bootstrap.ps1 is created with my typical contents." {
        git-init -userEmail 'test@gmail.com' -userName 'test'
        $output = @'
Write-verbose -verbose "Bootstrapping missing submodules..."
git submodule update --init --recursive

'@
        get-childitem bootstrap.ps1 | get-content | Out-String | Should Be $output
    }

    It "setup.ps1 is created with my typical contents." {
        git-init -userEmail 'test@gmail.com' -userName 'test'
        $output = @'
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
        get-childitem setup.ps1 | get-content | Out-String | Should Be $output
    }

    It "update.ps1 is created with my typical contents." {
        git-init -userEmail 'test@gmail.com' -userName 'test'
        $output = @'
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
        get-childitem update.ps1 | get-content | Out-String | Should Be $output
    }


}<#END Describe "git-init"#>
