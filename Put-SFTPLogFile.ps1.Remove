function Put-SFTPLogFile{
<#
    .SYNOPSIS
        This Script will upload file to the SFTP location, and also create the missing folders if not exist.
    .DESCRIPTION
        This Script will upload file to the SFTP location, and also create the missing folders if not exist.
    .PARAMETER HostName
        The Host IP or Name of the SFTP server
    .PARAMETER UserName
        The SFTP Username to be used to connect
    .PARAMETER Password
        The SFTP password for the specified user
    .PARAMETER LocalPath
        The Local File that needs to be uploaded to the SFTP Server
    .PARAMETER RemotePath
        The SFTP File Location to upload the file. The missing folders would be created
    .PARAMETER DllLocation
        The location of the WinSCP dll to be used. Default location would be where the powershell script file is placed.
    .NOTES 
        Please ensure the location of the WinSCP Dll file.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,Position=1,HelpMessage="The Host IP or Name of the SFTP server")]
        [string] $HostName,
        [Parameter(Mandatory=$true,Position=2,HelpMessage="The SFTP Username to be used to connect")]
        [string] $UserName,
        [Parameter(Mandatory=$true,Position=3,HelpMessage="The SFTP password for the specified user")]
        [string] $Password,
        [Parameter(Mandatory=$true,Position=4,HelpMessage="The Local File that needs to be uploaded to the SFTP Server")]
        [ValidateScript({Test-Path $_})]
        [string] $LocalPath,
        [Parameter(Mandatory=$true,Position=5,HelpMessage="The SFTP File Location to upload the file. The missing folders would be created")]
        [string] $RemotePath,
        [Parameter(HelpMessage="The location of the WinSCP dll to be used. Default location would be where the powershell script file is placed.")]
        [ValidateScript({Test-Path $_})]
        [string] $DllLocation = '.\WinSCPnet.dll'
    )
    Write-Verbose "Adding refrence to the WinSCP dll file {0}" -f $DllLocation
    Add-Type -Path $DllLocation
    Write-Debug "Creating the WinSCP session options object"
    $sessionOption = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::sftp
        HostName = $HostName
        UserName = $UserName
        Password = $Password
    }
    Write-Debug "Creating the WinSCP Session object"
    $session = New-Object WinSCP.Session
    try{
        Write-Debug "Opening the WinSCP session with the session options {0}" -f $sessionOption 
        $session.Open($sessionOption)
        Write-Verbose "Splitting the remove path so that we can validated whether the foldes exist or not"
        $remoteDirsArr = $remotePath.Split("/")
        #This needs to be done because if the path starts with / then the first element in the array is a blank
        #And we nedd to skip that
        if($remotePath.StartsWith("/"))
        {
            $i = 1;
        }else
        {
            $i = 0;
        }
        $combinedPath = "";
        Write-Debug "Checking all the directories on the SFTP server"
        For (; $i -le ($remoteDirsArr.Length-1) ; $i++)
        {
            Write-Verbose "Processing for the folder {0} under the folder {1}" -f $remoteDirsArr[$i] $combinedPath
            $combinedPath = $session.combinePaths($combinedPath,$remoteDirsArr[$i])
            Write-Verbose "Checking if the folder {0} exists" -f $combinedPath
            if(!($session.FileExists($combinedPath)))
            {
                WriteHost "Creating directory :: " $combinedPath
                $session.CreateDirectory($combinedPath)
            }
        }
        Write-Host "Copying file :" $localPath " to :" $remotePath
        $result = $session.PutFiles($localPath,$remotePath)
        Write-Host "the transfer status is :: {0}" -f $result.isSuccess
    }
    finally
    {
        $session.Dispose()
    }
}