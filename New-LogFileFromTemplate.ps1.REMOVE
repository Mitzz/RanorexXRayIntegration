function New-LogFileFromTemplate{
    <#
        .SYNOPSIS
            This script will create a log file from a template log file.
        .DESCRIPTION
            This script will create a log file from a template log file. The Template log file would have to contain the following format.
                == <CURRDATE-noOfDaystoSubtract,dateformat> ATM02 ==
                == <CURRDATE+noOfDaystoAdd,dateformat> ATM02 ==
            Example :
            1.If the input file contains the following log line for date 
                == <CURRDATE-2,MMM dd, yyyy> ATM02 ==
            Lets say Current date is 'Aug 31, 2017' then the output in the processed file would be 
                == Aug 29, 2017 ATM02 ==
            2. If the input file contains the following log line for date 
                == <CURRDATE-1,MMM dd, yyyy> ATM02 ==
            Lets say Current date is 'Aug 31, 2017' then the output in the processed file would be 
                == Aug 30, 2017 ATM02 ==
            3. If the input file contains the following log line for date
                == <CURRDATE+1,MMM dd, yyyy> ATM02 ==
            Lets Say Current date is 'Aug 31, 2017' then the output in the processed file would be
                == Sep 01, 2017 ATM02 ==
        .PARAMETER TemplateLogFile
            The location of the template Log file. The data from which has to be processed.
        .PARAMETER OutputFile
            The location of the Output file name. The Processed data would be placed in this file.
        .LINK
            
            https://docs.microsoft.com/en-us/dotnet/standard/base-types/standard-date-and-time-format-strings

        .NOTES
            This function would replace <CURRDATE-'noOfDaystoSubtract',dateformat> in any text file. But it was desined for VISTA audit.log file. 
            And for other log files it may need refactoring.

    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,Position=1,HelpMessage="The Template File from which we need to create the updated log file")]
        [ValidateScript({Test-Path $_ })]
        [string] $TemplateLogFile,
        [Parameter(Mandatory=$true,Position=2,HelpMessage="The Output file for processed output. If the file exists then the file would be replaced")]
        [string] $OutputFile
    )
    try
    {
		$TemplateLogFilePath = Resolve-Path -Path $TemplateLogFile
        $intermediateOutputPath = Join-Path (pwd) $OutputFile
        $OutputFilePath = [System.IO.Path]::GetFullPath($intermediateOutputPath)
        Write-Debug ("the path is {0},{1}" -f $TemplateLogFilePath,$OutputFilePath)
        $TemplateFile = New-Object System.IO.StreamReader -Arg $TemplateLogFilePath
        $ProcessedFile = New-Object System.IO.StreamWriter -Arg $OutputFilePath
		
        # $TemplateFile = New-Object System.IO.StreamReader -Arg $TemplateLogFile
        # $ProcessedFile = New-Object System.IO.StreamWriter -Arg $OutputFile
        $RegExPattern = '<CURRDATE([-+])(\d),(.+?)>'
        $currDate = Get-Date
        Write-Debug("Processing the file line by line using streams")
        while(($line = $TemplateFile.ReadLine()) -ne $null)
        {
            $matchesList = Select-String -Pattern $RegExPattern -InputObject $line
            Write-Verbose ("The size of the matched list is {0}" -f $matchesList.Matches.Count)
            if($matchesList -eq $null)
            {
                $ProcessedFile.WriteLine($line)
            }
            else
            {
                # Matches link for ref https://msdn.microsoft.com/en-us/library/twcw2f1c(v=vs.110).aspx
                # Regex Class Link for ref https://msdn.microsoft.com/en-us/library/system.text.regularexpressions.regex(v=vs.110).aspx

                #The regex that would be used for identifying the rows in the template
                [regex]$baseRegex = $RegExPattern
                #building the match object for the current line
                $match = $baseRegex.Match($line)
                $replacedLine = $line
                while ($match.Success)
                {
                    Write-Verbose ("calculating the number of days to be subtracted/added")
                    if($match.Groups[1].Value -eq "+")
                    {
                        $noOfDays = $match.Groups[2].Value
                    }
                    else
                    {
                        #Taking the default value as negative
                        $noOfDays = -$match.Groups[2].Value
                    }
        
                    Write-Verbose("the value for the number of days is :: {0}" -f $noOfDays)
                    $newDateObjForReplacement = $currDate.AddDays($noOfDays)

                    $DateFormat = $match.Groups[3].Value
                    Write-Verbose("the new date object calculated is :: {0} and the DateFormat from regex is :: {1}" -f $newDateObjForReplacement,$DateFormat)
                    $formattedDateStr = $newDateObjForReplacement.ToString($DateFormat)
        
                    Write-Verbose("The Formatted date is :: {0}" -f $formattedDateStr)
                    $replacementStr = $match.Groups[0].Value

                    $replacedLine = $replacedLine -replace($replacementStr,$formattedDateStr)

                    Write-Verbose("Performing the next match in the line")
                    $match = $match.NextMatch()
                }
                
                Write-Debug("The formatted Line is :: {0}" -f $replacedLine)
                $ProcessedFile.WriteLine($replacedLine)
            }
        }
        Write-Debug("File Processing complete, Closing all the resources")
        $ProcessedFile.Flush()
        $ProcessedFile.Close()
        $TemplateFile.Close()
    }
    finally
    {
        if($ProcessedFile -ne $null)
        {
            $ProcessedFile.Dispose()
        }
        if($TemplateFile -ne $null)
        {
            $TemplateFile.Dispose()
        }
    }
    
}