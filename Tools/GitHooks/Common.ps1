function ExitWithCode
{ 
    param
    (
        [int] $exitCode
    )

    $host.SetShouldExit($exitCode)
    exit
}

function ExitWithSuccess
{
    ExitWithCode 0
}

function ExitWithFailure
{
    ExitWithCode 1
}

function ProcessErrors
{
    param
    (
        [ErrorRecord[]] $Errors
    )

    Write-Error ($Errors | Out-String)
    ExitWithFailure
}

function Get-HooksConfiguration
{
    $scriptFolder = Split-Path $script:MyInvocation.MyCommand.Path -Parent
    ([xml] (Get-Content "$scriptFolder\HooksConfiguration.xml")).HooksConfiguration
}

function Check-IsMergeCommit
{
    (git rev-parse --verify --quiet HEAD^2) -ne $null
}

function Get-CurrentBranchName
{
    git rev-parse --abbrev-ref HEAD
}

function Get-MergedBranchName
{
    Get-BranchName HEAD^2
}

function Get-TrackedBranchName
{
    param
    (
        [string] $BranchName
    )

    if (-not $BranchName)
    {
        $BranchName = Get-CurrentBranchName
    }

    $remote = git config branch.$BranchName.remote
    if (-not $remote)
    {
        $remote = "origin"
    }

    $remoteBranch = "$remote/$BranchName"

    $remoteBranches = (git branch --remote) -replace "^  "

    if ($remoteBranches -contains $remoteBranch)
    {
        return $remoteBranch
    }
    else
    {
        return $null
    }
}

function Check-IsPullMerge
{
    (Get-MergedBranchName) -eq (Get-TrackedBranchName)
}

function Get-CurrentCommitMessage
{
    git log -1 --pretty=%s
}

function Check-IsBranchPushed
{
    (Get-TrackedBranchName) -ne $null
}

function Get-BranchName
{
    param
    (
        [string] $Commit
    )

    (git name-rev --name-only $Commit) -replace "remotes/"
}

function Test-FastForward
{
    param
    (
        [string] $From,
        [string] $To
    )

    $From = git rev-parse $From
    $mergeBase = git merge-base $From $To

    $mergeBase -eq $From
}