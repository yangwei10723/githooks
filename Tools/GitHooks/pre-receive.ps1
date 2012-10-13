#requires -version 2.0

[CmdletBinding()]
param
(
    [string] $PrevCommit,
    [string] $NewCommit,
    [string] $RefName
)

$ErrorActionPreference = "Stop"

$scriptFolder = Split-Path $MyInvocation.MyCommand.Path -Parent

. "$scriptFolder\Common.ps1"

Trap [Exception] `
{
    Write-Error ($_ | Out-String)
    ExitWithFailure
}

$missingCommit = "0000000000000000000000000000000000000000"

$branchName = Get-BranchName $RefName

if ($PrevCommit -eq $missingCommit)
{
    Write-Debug "$branchName is a new branch"
    ExitWithSuccess
}

$mergeCommits = git log --merges --format=%H "$PrevCommit..$NewCommit"
[Array]::Reverse($mergeCommits)

foreach ($mergeCommit in $mergeCommits)
{
    if (-not (Test-IsAncestorCommit -Commit $mergeCommit -AncestorCommit $PrevCommit))
    {
        $commitMessage = git log -1 $mergeCommit --format=oneline
        Write-Warning "The following commit should not exist in branch $branchName`n$commitMessage"
        ExitWithFailure
    }
}

ExitWithSuccess