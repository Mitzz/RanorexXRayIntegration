function Update-AutomationJobProperties{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,HelpMessage="The location from where to pick the original properties file")]
        [string] $templatePropertiesFolder,
        [Parameter(Mandatory=$true,HelpMessage="The Output location where to place the updated properties file")]
        [string] $outputFolderLocation,
        [Parameter(Mandatory=$true,HelpMessage="The Azure Subscription name to use of the environment on which to execute the Automation Runs")]
        [string] $AzureSubscriptionName,
        [Parameter(Mandatory=$false,HelpMessage="To enable download of the Azure Blob Storage In case of failures.")]
        [string] $downloadAzureStorageBlob
    )

    $templatePropertiesFolder = Resolve-Path -Path $templatePropertiesFolder
    $outputFolderLocation = Resolve-Path -Path $outputFolderLocation

    $newFrameworkDefaultConfigFile = Join-Path $outputFolderLocation "framework-default-config.properties"
    $newDefaultTestcaseConigFile = Join-Path $outputFolderLocation "default-testcase-config.properties"
    $newseleniumDataConfigFile = Join-Path $outputFolderLocation "selenium-data.properties"

    $bkpFrameworkDefaultConfigFile = Join-Path $outputFolderLocation "framework-default-config.properties.bkp"
    $bkpDefaultTestcaseConigFile = Join-Path $outputFolderLocation "default-testcase-config.properties.bkp"
    $bkpseleniumDataConfigFile = Join-Path $outputFolderLocation "selenium-data.properties.bkp"

    Rename-FileToBackUpIfExists $newFrameworkDefaultConfigFile $bkpFrameworkDefaultConfigFile -ErrorAction Stop
    Rename-FileToBackUpIfExists $newDefaultTestcaseConigFile $bkpDefaultTestcaseConigFile -ErrorAction Stop
    Rename-FileToBackUpIfExists $newseleniumDataConfigFile $bkpseleniumDataConfigFile -ErrorAction Stop

    if($templatePropertiesFolder -eq $outputFolderLocation){
        Write-Warning ("the template folder location is same as that of the output folder location")
        $origFrameworkDefaultConfigFile = Join-Path $templatePropertiesFolder "framework-default-config.properties.bkp"
        $origDefaultTestcaseConigFile = Join-Path $templatePropertiesFolder "default-testcase-config.properties.bkp"
        $origseleniumDataConfigFile = Join-Path $templatePropertiesFolder "selenium-data.properties.bkp"
    }else{
        $origFrameworkDefaultConfigFile = Join-Path $templatePropertiesFolder "framework-default-config.properties"
        $origDefaultTestcaseConigFile = Join-Path $templatePropertiesFolder "default-testcase-config.properties"
        $origseleniumDataConfigFile = Join-Path $templatePropertiesFolder "selenium-data.properties"
    }


    #Reading and processing Files one by one.
    $oldfilesArray = @($origFrameworkDefaultConfigFile,$origDefaultTestcaseConigFile,$origseleniumDataConfigFile)
    $newfilesMap = @{}
    $newfilesMap.Add($origFrameworkDefaultConfigFile,$newFrameworkDefaultConfigFile)
    $newfilesMap.Add($origDefaultTestcaseConigFile,$newDefaultTestcaseConigFile)
    $newfilesMap.Add($origseleniumDataConfigFile,$newseleniumDataConfigFile)


    ForEach($oldFile in $oldfilesArray){
        $newFileStr = $newfilesMap.Get_Item($oldFile)
        $newFile = [System.IO.Path]::GetFullPath($newFileStr)
        #Creating the missing directories for new output folder        
        [System.IO.FileInfo] $newFileInfo = New-Object System.IO.FileInfo -Arg $newFile
        $newFileInfo.Directory.Create()
        #Completed Creating the new Directories
        Write-Verbose ("Creating the reader for old file :: {0}, And writer for the new file :: {1}" -f $oldFile,$newFile)
        $oldFileReader = New-Object System.IO.StreamReader -Arg $oldFile
        $newFileWrite = New-Object System.IO.StreamWriter -Arg $newFile
        try{
            Write-Debug ("Reading the lines from the template file")
            while(($line = $oldFileReader.ReadLine()) -ne $null){
                Write-Verbose ("Processing the line {0}" -f $line)
                if($line -like '*=*'){
                    $propsPair = $line.Split('=',2)
                    Write-Debug ("Processing the property key :: {0}" -f $propsPair[0])
                    Write-Verbose ("The template value are Key {0} = Value {1}" -f $propsPair[0],$propsPair[1])
                    switch($propsPair[0])
                    {
                        #Write the cases here for all the keys that we would want to update. 
                        #Also, ensure correct handling in cases where in the values have to kept the same as that of template, or the parameter is not 
                        "azure-subscription-name" { 
                            $propsLine = Get-UpdatedPropsLine -PropName $propsPair[0] -PropValue $AzureSubscriptionName
                        }
                        "download-azure-storage-blob" {
                            if($downloadAzureStorageBlob){
                                $propsLine = Get-UpdatedPropsLine -PropName $propsPair[0] -PropValue $downloadAzureStorageBlob
                            }else{
                                $propsLine = $line
                            }
                        }
                        default {
                            Write-Verbose ("No Switch found for the provided property key {0}, writing the line as it is" -f $propsPair[0])
                            $propsLine = $line
                        }
                    }
                    Write-Verbose("The updated props line is {0}" -f $propsLine)
                    $newFileWrite.WriteLine($propsLine)
                    $propsLine = $null
                }else{
                    $newFileWrite.WriteLine($line)
                }
            }
            Write-Verbose("Flushing the stream {0}" -f $newFileWrite)
            $newFileWrite.Flush()
        }
        finally
        {
           Write-Verbose("Closing both the streams Reader :: {0}, Writer :: {1} " -f $oldFileReader,$newFileWrite)
           $newFileWrite.Close()
           $oldFileReader.Close() 
        }
    }

    Write-Information ("Completed the update for all the props file for the ui automation job")
}

function Rename-FileToBackUpIfExists{
    [CmdletBinding()]
    Param(
        [Parameter(Position=1,Mandatory=$true,HelpMessage="The File to be renamed")]
        [System.IO.FileInfo] $oldFilePath,
        [Parameter(Position=2,Mandatory=$true,HelpMessage="The new file name")]
        [System.IO.FileInfo] $newFileNane
    ) 
    if(Test-Path $oldFilePath -PathType Leaf){
        Write-Verbose ("The file {0} is already present. trying to rename it to {1}" -f $oldFilePath,$newFileNane)
        #trying to rename the file.
        Move-Item $oldFilePath $newFileNane -Force
        return $true
    }else{
        Write-Verbose ("the file {0} is not present at the specified location"-f $oldFilePath)
        return $false
    }
}

function Get-UpdatedPropsLine{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,HelpMessage="The Property name")]
        [string] $PropName,
        [Parameter(Mandatory=$true,HelpMessage="The Property value")]
        [string] $PropValue,
        [Parameter(Mandatory=$false,HelpMessage="Handle space with double quotes")]
        [switch] $AddDoubleQuote=$false
    )
     if($PropValue -match "\s"){
        $updatedPropValue = $PropValue -replace "\s","\ "
        if($AddDoubleQuote){
            $updatedPropValue = -Join ("\\`"" ,$updatedPropValue,"\\`"")
        }
     }else{
        $updatedPropValue = $PropValue
     }
     
     Write-Verbose("The input prop value is :: {0}, The updated prop value is :: {1}" -f $PropValue,$updatedPropValue)
     [string] $line = -Join($PropName,"=",$updatedPropValue)
     Write-Verbose("The line for file writing is {0}" -f $line)
     return $line
}

