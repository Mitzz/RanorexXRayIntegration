function Get-LatestModifiedFile{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,HelpMessage="The Folder From which we need to get the latest modified file",Position=1)]
        [string] $folderName
    )
    $varName = Get-ChildItem $folderName | sort LastWriteTime | select -last 1
    return $varName.Name
}