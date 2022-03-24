<#
    Add-Todo

    A PowerShell implementation for todotxt-cli

    TODOs:
    - Create basic implementation of adding items
    - Create basic implementation of listing items
#>

#region PRIVATE
function Get-TodoFile {
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
        [DateTime]$DueDate,
        [string[]]$Project,
        [switch]$CreateDate
    )

    $TodotxtPath = Get-TodoFile
    $TodoString = ""
    if($Severity) {
        $TodoString = "($Severity) "
    }
    if($CreateDate) {
        $TodoString += $(Get-Date -Format "yyyy-MM-dd ")
    }
    if($DueDate) {
        $TodoString += "due:" + $DueDate.ToString("yyyy-MM-dd")
    }
    $TodoString += $Item
    foreach($ProjectName in $Project){
        $TodoString += " +$ProjectName"
    }
    Out-File -FilePath $TodotxtPath -InputObject $TodoString -Append
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
        [DateTime]$DueDate,
        [string[]]$Project,
        [bool]$Exclusive=$false
    )

    $TodotxtPath = Get-TodoFile
    $TempTodoPath = "$ENV:TEMP\44f5a903-73bb-4977-a846-4876e56a4ca7.txt"
    if($Find -eq "" -and $Severity -eq "" -and $DueDate -eq $null -and $Project.Count -eq 0){
        Get-Content $TodotxtPath
        Write-Host "Count: $((Get-Content $TodotxtPath).Count)"
        return
    }
    $Results
    if($Find) {
        Write-Verbose "Searching for items matching $Find"
        $Results = Select-String $Find $TodotxtPath
    }
    else {
        if($Severity) {
            Write-Verbose "Searching Severity"
            $Results = Select-String "($Severity)" -SimpleMatch $TodotxtPath
            Out-File -FilePath $TempTodoPath -InputObject ($Results).Line
            $TodotxtPath = $TempTodoPath
        }
        if($DueDate){
            Write-Verbose ("Searching for items with due date " + $DueDate.ToString("yyyy-MM-dd"))
            $Results = Select-String $("due:" + $DueDate.ToString("yyyy-MM-dd")) -SimpleMatch $TodotxtPath
            Out-File -FilePath $TempTodoPath -InputObject ($Results).Line
            $TodotxtPath = $TempTodoPath
        }
        if($Project){

            $SearchTerm = ""
            $TermCount = 0

            foreach($ProjectName in $Project)
            {
                if($TermCount -eq 0) {
                    $SearchTerm = "\+$ProjectName"
                }
                else {
                    $SearchTerm += "|\+$ProjectName"
                }
                $TermCount++
            }
            Write-Verbose "Searching for items with search term: $SearchTerm"
            $Results = Select-String $SearchTerm $TodotxtPath
        }
    }

    $Count = 0
    foreach($Item in $Results) {
        if($Item.Line.StartsWith("//") -or $Item.Line.StartsWith("x")) {
            continue
        }
        else{
            Write-host $Item.Line
           $Count++
        }
    }
    Write-Host "Count: $Count"
}

# Think about how to handle this case... and maybe allow pipe?
function Complete-Todo {
    [CmdletBinding()]
    param(
        [string]$Item,
        [int]$Number,
        [switch]$Confirm
    )
    $TodotxtPath = Get-TodoFile
    if($Item -eq ""){
        $i = 1
        $TodoList = New-Object -TypeName "System.Collections.ArrayList"
        Get-Content $TodotxtPath | ForEach-Object {
            if(!$_.StartsWith("//") -and $_.StartsWith("x ")){
                Write-Host "$i) $_"
                $TodoList.Add($_)
                $i++
            }
        }

        [int]$s = Read-Host -Prompt "Item number: "
        if($s -gt $i -or $s -lt 0){
            Write-Error "Invalid Selection"
            return
        }
        $SelectedItem = $TodoList[$s]
        (Select-String $SelectedItem -SimpleMatch $TodotxtPath).LineNumber

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