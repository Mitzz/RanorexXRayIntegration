$A = Select-String -Pattern "<CURRDATE-(\d)>" -Path "C:\Users\mundraa\Desktop\Use_Case_1_Test_Data\Txn_Failure_Rate_FunctionalTest_UC01_TC001\ATM03_Single_Failure_2Of15_Template.LOG"
$highestValue = 0;
ForEach($single in $A)
{
    if($single.Matches[0].Groups[1].Value -gt $highestValue)
    {
        $highestValue = $single.Matches[0].Groups[1].Value
    }
}


Write-Host "the highest value is :: $highestValue"
$content = Get-Content -Path "C:\Users\mundraa\Desktop\Use_Case_1_Test_Data\Txn_Failure_Rate_FunctionalTest_UC01_TC001\ATM03_Single_Failure_2Of15_Template.LOG"
for($i = 0; $i -ile $highestValue; $i++)
{
    $replacementString = -join("<CURRDATE-",$i,">")
    $currDate = Get-Date
    $calculatedDate = $currDate.AddDays(-$i)
    Write-Host $calculatedDate
    $formattedDate = $calculatedDate.ToString("MMM dd, yyyy")
    Write-Host "The Formatted date is ::" $formattedDate
    $content = $content -replace($replacementString,$formattedDate)
}

Set-Content -Path "C:\Users\mundraa\Desktop\Use_Case_1_Test_Data\Txn_Failure_Rate_FunctionalTest_UC01_TC001\ATM03_Single_Failure_2Of15.LOG" -Value $content

#322