function Delete-SFTPLogFile{
<#
    .SYNOPSIS
        This Script will upload file to the SFTP location, and also create the missing folders if not exist.
    .DESCRIPTION
        This Script will upload file to the SFTP location, and also create the missing folders if not exist.
    .PARAMETER HostName
        The Host IP or Name of the SFTP server
    .PARAMETER SSHFingerprint
        The SSH Fingerprint
    .PARAMETER UserName
        The SFTP Username to be used to connect
    .PARAMETER Password
        The SFTP password for the specified user
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
        [Parameter(Mandatory=$true,Position=4,HelpMessage="The SFTP File/Folder Location to Delete the file. The missing folders would be created")]
        [string] $RemotePath,
        [Parameter(HelpMessage="The location of the WinSCP dll to be used. Default location would be where the powershell script file is placed.")]
        [ValidateScript({Test-Path $_})]
        [string] $DllLocation = '.\WinSCPnet.dll'
    )
    Write-Verbose ("Adding refrence to the WinSCP dll file {0}" -f $DllLocation)
    Add-Type -Path $DllLocation
    Write-Debug "Creating the WinSCP session options object"
    $sessionOption = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::sftp
        HostName = $HostName
        UserName = $UserName
        Password = $Password
        SshHostKeyFingerprint = "ssh-ed25519 256 26:45:9d:f3:de:c4:a3:c0:ea:d6:4a:ef:7b:e8:5b:5d"
    }
    Write-Debug "Creating the WinSCP Session object"
    $session = New-Object WinSCP.Session
    try{
        Write-Debug ("Opening the WinSCP session with the session options {0}" -f $sessionOption)
        Write-Debug ("Deleting a remote file from WinSCP server " -f $sessionOption)
        $session.Open($sessionOption)
        $session.RemoveFiles($RemotePath)
        Write-Host ("File is Deleted :: {0}" -f $result.isSuccess)
    }
    finally
    {
        $session.Dispose()
    }
}