<#
    Add-Todo

    A PowerShell implementation for todotxt-cli

    TODOs:
    - Create basic implementation of adding items
    - Create basic implementation of listing items
#>

#region PRIVATE
function Get-TodoFile {
    # TODO(will): Use registry instead of env variables
    $TodotxtPath = [System.Environment]::GetEnvironmentVariable("todotxt", "User")
    if($null -eq $TodotxtPath){
        $TodotxtPath = $ENV:HOME + "\todo.txt"
    }

    if(!(Test-Path $TodotxtPath)){
        New-Item -FilePath $TodotxtPath -ItemType File
    }

    return $TodotxtPath
}

#endregion

#region PUBLIC

# FUNCTION  : Add-Todo
# PURPOSE   : Add items to todo.txt file
function Add-Todo {

    <#
    .SYNOPSIS
        Adds an item to a todo.txt file
    .DESCRIPTION
        Adds an input field as an object in a todo.txt file.
    .EXAMPLE
        Add-Todo -Item "Go grocery shopping" -Severity A -CreateDate -DueDate "2022-03-25"
    .LINK
        Core idea: https://github.com/todotxt/todo.txt
    #>
    [CmdletBinding()]
    param(
        [string]$Item,
        [string]$Severity,
        [string]$DueDate,
        [switch]$CreateDate,
        [switch]$Help
    )

    if($Help){
        start "https://github.com/todotxt/todo.txt"
    }

    $TodotxtPath = Get-TodoFile

    if($CreateDate){
        Out-File -FilePath $TodotxtPath -InputObject $(Get-Date -Format "yyyy-MM-dd ") -Append -NoNewLine
    }

    Out-File -FilePath $TodotxtPath -InputObject $Item -Append
}

function Get-Todo {
    <#
    .SYNOPSIS
        Retrieves items from todo.txt
    .DESCRIPTION
        Retrievs items from todo.txt to match input parameters
    .EXAMPLE
    #>

    [CmdletBinding()]
    param(
        [string]$Find,
        [string]$Severity,
        [string]$DueDate,
        [string]$Project,
        [bool]$Exclusive=$false
    )

    $TermList = ($Find,$Severity,$Project)

    $TodotxtPath = Get-TodoFile

    if($Find -eq "" -and $Severity -eq "" -and $DueDate -eq "" -and $Project -eq ""){
        Get-Content $TodotxtPath
    }
    else{
        # Priority is started
        $SearchTerm = ""
        $TermCount = 0
        foreach($Term in $TermList){
            if($Term -ne ""){
                if($TermCount -ge 1){
                    $SearchTerm += "|"
                }
                $SearchTerm += $Term
                $TermCount++
            }
        }
        Write-Verbose "Using search term $SearchTerm, Term Count: $TermCount"
        # TODO(will): think how to handle due dates
        (Select-String $SearchTerm $TodotxtPath).Line
    }
}

function Clear-Todo {
    [CmdletBinding()]
    param(
        [switch]$Confirm
    )

    $TodotxtPath = Get-TodoFile

    if(!$Confirm) {
        $Result = Read-Host -Prompt "Are you sure you would like to clear your todo.txt? (y/N) "
        if($Result -ne "y") {
            return
        }
    }

    Clear-Content -Path $TodotxtPath

}

#endregion