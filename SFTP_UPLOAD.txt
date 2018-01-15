echo Starting....
try{

    Add-Type -Path "C:\softwares_installers\putty\WinSCP-5.9.6-Automation\WinSCPnet.dll"

    $sessionOption = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::sftp
        HostName = "52.187.112.108"
        UserName = "ftpadmin"
        Password = "ftpadmin"
    }

    $session = New-Object WinSCP.Session
    # this local path can contain only one single file
    $localPath = "C:\Users\mundraa\Desktop\Use_Case_1_Test_Data\Txn_Failure_Rate_FunctionalTest_UC01_TC001\ATM01_Single_Failure_2Of15.LOG"
    #Remote Path, all the missing directories in this path will be created. The file will be copied with the file name on the local machine
    $remotePath = "/files/QA4/20170827/VISTA/"

    try{
        $session.Open($sessionOption)
        $remoteDirsArr = $remotePath.Split("/")
        if($remotePath.StartsWith("/"))
        {
            $i = 1;
        }else
        {
            $i = 0;
        }
        $combinedPath = "";
        For (; $i -le ($remoteDirsArr.Length-1) ; $i++)
        {
            $combinedPath = $session.combinePaths($combinedPath,$remoteDirsArr[$i])
            if(!($session.FileExists($combinedPath)))
            {
                WriteHost "Creating directory :: " $combinedPath
                $session.CreateDirectory($combinedPath)
            }
        }
        Write-Host "Copying file :" $localPath " to :" $remotePath
        $result = $session.PutFiles($localPath,$remotePath)
        Write-Host "the transfer status is ::" $result.Check()
    }
    finally
    {
        $session.Dispose()
    }
}
catch [Exception]
{
    Write-Host "Error: {0}" -f $_.Exception.Message
    $_.Exception.Message
}
