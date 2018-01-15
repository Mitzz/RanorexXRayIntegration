. (Join-Path $PSScriptRoot Get-AzureContextUsingLoginAndSubscription.ps1)
function Run-BatchJobSlices{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,HelpMessage="The Azure User name, for which we want to perform the login")]
        [string] $UserName,
        [Parameter(Mandatory=$false,HelpMessage="The Password for the Azure Userfor which we want to perform login")]
        [string] $Password,
        [Parameter(Mandatory=$false,HelpMessage="The Powershell Credentials account for which we will perform login")]
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory=$true,HelpMessage="The Azure Subscription Name for the given user")]
        [string] $SubscriptionName,
        [Parameter(Mandatory=$true,HelpMessage="The Azure DataFactory Name for which the slices would have to be triggered")]
        [string] $DatafactoryName,
        [Parameter(Mandatory=$true,HelpMessage="The Resource Group name under which the data factory is created")]
        [string] $ResourceGroupName,
        [Parameter(Mandatory=$true,HelpMessage="The Azure Pipeline name for which the slices would have to be triggered")]
        [string] $PipelineName,
        [Parameter(Mandatory=$true,HelpMessage="The Start Date of the slices")]
        [DateTime] $StartDate,
        [Parameter (Mandatory=$false,HelpMessage="The End date of the slices")]
        [DateTime] $EndDate,
        [Parameter(Mandatory=$false,HelpMessage="Switch to set all the slices after the Start date to be executed or only the slices between the Start date and end date to be executed")]
        [switch] $AllSlices,
        [Parameter(Mandatory=$false,HelpMessage="Switch to identify, whether to wait for all the slices to be completed")]
        [switch] $WaitForSlicesTobeCompleted
    )
    
    #Initailizing the default variables.
    $currDate = Get-Date
    
    if($EndDate -eq $null)
    {
        $EndDate = $currDate.AddDays(-1)
    }

    Write-Debug ("Getting the azure context for the provided user or credentails")
    Get-AzureContextUsingLoginAndSubscriptionName -UserName $UserName -Password $Password -Credential $Credential -SubscriptionName $SubscriptionName
    
    Write-Debug ("Getting the datafactory")
    $dataFactory = Get-AzureRmDataFactory -ResourceGroupName $ResourceGroupName -Name $DatafactoryName
    Write-Verbose ("The DataFactory information is :: {0}" -f $dataFactory)
    
    Write-Debug ("Getting the Pipeline from the data factory")
    $pipeLineInfo = Get-AzureRmDataFactoryPipeline -DataFactory $dataFactory -Name $PipelineName
    Write-Verbose("The pipeline info received is :: {0}" -f $pipeLineInfo)
    
    $pipeLineActivitiesList = $pipeLineInfo.Properties.Activities
    Write-Verbose("The Pipeline Activities are :: {0}" -f {$pipeLineActivitiesList | Format-Table | Out-String})

    Write-Debug("Getting the name of outputs to get the slices for all the activities")
    $datasetNamesList = New-Object System.Collections.ArrayList
    foreach($pipeLineActivity in $pipeLineActivitiesList)
    {
        foreach($output in $pipeLineActivity.Outputs)
        {
            $datasetNamesList.Add($output.Name)
        }        

    }
    
    #is slice available check needed
    forEach($datasetName in $datasetNamesList)
    {
        $sliceList = Get-AzureRmDataFactorySlice $dataFactory -DatasetName $datasetName -StartDateTime $StartDate -EndDateTime $EndDate
        if($sliceList -eq $null)
        {
            throw ("No Slices Available for dataset :: {0}, Start Date :: {1}, End Date :: {2}" -f $datasetName,$StartDate,$EndDate)
        }
    }

    Wait-ForAllSlicesToBeCompleted -dataFactory $dataFactory -datasetNamesList $datasetNamesList -StartDate $StartDate -EndDate $EndDate
    
    Write-Information ("Calculating the Update type for the slices")
    
    if($AllSlices -or ($currDate.Date -eq $EndDate))
    {
        $updateType = 'UpstreamInPipeline'
    }
    else
    {
        $updateType = 'Individual'
    }

    Write-Information("Setting the status for all the slices to Waiting..")

    $result = $true
    forEach($datasetName in $datasetNamesList)
    {
        Write-Verbose ("Setting the Status as waiting for all the slices between {0} and {1} for dataset :: {2}, using update type {3}" -f $StartDate,$EndDate,$datasetName,$updateType)
        $currResult = Set-AzureRmDataFactorySliceStatus -DataFactory $dataFactory -DatasetName $datasetName -StartDateTime $StartDate -EndDateTime $EndDate -UpdateType $updateType -Status Waiting
        Write-Verbose ("The result for setting the status as waiting is ::{0}" -f $currResult)
        $result = $result -and $currResult
    }

    Write-Information("The result of setting the pipeline status is {0}" -f $result)

    Write-Verbose("The status of variable WaitForSlicesTobeCompleted is {0} " -f $WaitForSlicesTobeCompleted)
    if($WaitForSlicesTobeCompleted)
    {
        Start-Sleep -Seconds 480
        Write-Verbose("Waiting for slices to be executed after changing their status")
        Wait-ForAllSlicesToBeCompleted -dataFactory $dataFactory -datasetNamesList $datasetNamesList -StartDate $StartDate -EndDate $EndDate
    }

    Write-Information("Getting the list of all the runs id that were executed, along with their statuses")

    $resultMap = @{}

    forEach($datasetName in $datasetNamesList)
    {
        $sliceList = Get-AzureRmDataFactorySlice $dataFactory -DatasetName $datasetName -StartDateTime $StartDate -EndDateTime $EndDate
        $psRunList = New-Object System.Collections.ArrayList
        foreach($slice in $sliceList)
        {
            try
            {
                $latestRun = Get-LatestRunForSlice -dataFactory $dataFactory -datasetName $datasetName -StartDate $slice.Start
            }
            catch
            {
                Write-Warning ("There was no data found for the slice {0}" -f $slice.ToString())
                $latestRun = $null
            }
            $psRunList.Add($latestRun)
        }
        $resultMap.Add($datasetName,$psRunList)
    }

    return $resultMap
}

# ####################################################################################################################

function Wait-ForAllSlicesToBeCompleted{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,HelpMessage="The DataFactory object of the data set name")]
        [Microsoft.Azure.Commands.DataFactories.Models.PSDataFactory] $dataFactory,
        [Parameter(Mandatory=$true,HelpMessage="The List of Datasetname for which to wait for all the slices to be completed")]
        [string[]]$datasetNamesList,
        [Parameter(Mandatory=$true,HelpMessage="The Start date for the slices to be waited for")]
        [DateTime] $StartDate,
        [Parameter(Mandatory=$false,HelpMessage="The Start date for the slices to be waited for")]
        [DateTime] $EndDate,
        [Parameter(Mandatory=$false,HelpMessage="The wait before checking again for the slices if case if execution is going on")]
        [int] $waitTimeInSeconds=30,
        [Parameter (Mandatory=$false,HelpMessage="The list of status that would be considered valid")]
        [string[]] $validStatus = @('Ready','Failed','Skipped')
    )
    Write-Debug ("Waiting for the slices to be completed")
    $allSlicesReady = $true

    Write-Verbose ("Starting the do-until loop to process the slices")
    $allSlicesReady = $true

    do
    {
        $allSlicesReady = $true
        forEach($datasetName in $datasetNamesList)
        {
            $specificDataSliceList = Get-AzureRmDataFactorySlice $dataFactory -DatasetName $datasetName -StartDateTime $StartDate -EndDateTime $EndDate
            forEach($specifiedDataSlice in $specificDataSliceList)
            {
                if($validStatus -notcontains $specifiedDataSlice.State)
                {
                    if('Waiting' -eq $specifiedDataSlice.State)
                    {
                        try
                        {
                            $runList = Get-LatestRunForSlice -dataFactory $dataFactory -datasetName $datasetName -StartDate $specifiedDataSlice.Start

                        }
                        catch
                        {
                            Write-Verbose("The Slice is not having runs and hence this is the first run, we can procced without waiting for this slice")
                            Write-Verbose("The Exception occured is {0}" -f $_.Exception)
                        }
                    }
                    else
                    {
                        Write-Verbose("Inside the Wait-ForAllSlicesToBeCompleted else loop of the for loop.")
                        $allSlicesReady = $false
                    }
                }
                else
                {
                    Write-Verbose("the valid status contained in is :: {0}" -f $specifiedDataSlice.State)
                }
            }
        }
        Write-Verbose ("The value of allSlicesReady is {0}" -f $allSlicesReady)
        if($allSlicesReady -ne $true)
        {
            Start-Sleep -Seconds $waitTimeInSeconds
        }
    } while ($allSlicesReady -ne $true)
    Write-Debug("All the slices are in completed states")
}

# ####################################################################################################################

function Get-LatestRunForSlice(){
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,HelpMessage="The DataFactory object of the data set name")]
        [Microsoft.Azure.Commands.DataFactories.Models.PSDataFactory] $dataFactory,
        [Parameter(Mandatory=$true,HelpMessage="The List of Datasetname for which to wait for all the slices to be completed")]
        [string]$datasetName,
        [Parameter(Mandatory=$true,HelpMessage="The Start date for the slices to for which we need the latest run detail")]
        [DateTime] $StartDate
    )

    $sliceRunList = Get-AzureRmDataFactoryRun -DataFactory $dataFactory -DatasetName $datasetName -StartDateTime $StartDate
    if($sliceRunList -eq $null -or $sliceRunList.Count -eq 0)
    {
        throw ("There is no Run available for the slice with the startdate :: {0}, dataset name " -f $StartDate,$datasetName)
    }
    if($sliceRunList.Count -gt 1)
    {
        foreach($sliceRun in $sliceRunList){
            if($latestRun -eq $null)
            {
                $latestRun = $sliceRun
            }else
            {
                $currLatestRunDateTime = $latestRun.Timestamp
                $currSliceRunDateTime = $sliceRun.Timestamp
                if($currLatestRunDateTime -le $currSliceRunDateTime)
                {
                    $latestRun = $sliceRun
                }
            }
        }
    }
    else{
        $latestRun = $sliceRunList[0]
    }
    return $latestRun
}