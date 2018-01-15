function Get-AzureContextUsingLoginAndSubscriptionName{
    <#
        .SYNOPSIS
            This Script will perform a login into the azure RM account using the provided credentails and provide the Azure Context for the provided Subscription name
        .DESCRIPTION
            This Script will perform a login into the azure RM account using the provided credentails and provide the Azure Context for the provided Subscription name
        .PARAMETER UserName
            The Azure User name, for which we want to perform the login. not needed if providing -Credential
        .PARAMETER Password
            The Password for the Azure Userfor which we want to perform login.
        .PARAMETER Creds
            The Powershell Credentials account for which we will perform login. 
        .PARAMETER SubscriptionName
            The Azure Subscription Name for the given user, using which we would would set the Azure Context

    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,HelpMessage="The Azure User name, for which we want to perform the login")]
        [string] $UserName,
        [Parameter(Mandatory=$false,HelpMessage="The Password for the Azure Userfor which we want to perform login")]
        [string] $Password,
        [Parameter(Mandatory=$false,HelpMessage="The Powershell Credentials account for which we will perform login")]
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory=$true,HelpMessage="The Azure Subscription Name for the given user")]
        [string] $SubscriptionName
    )
    if($Credential -eq $null)
    {
        Write-Warning ("The creds are not provided as an argument in the command, using username and passord")
        Write-Warning ("It is advisable to use Credentails object")
        Write-Debug("The Username received is {0} and the password is {1}" -f $UserName,$Password)
        if(($UserName -eq $null -or $UserName -eq "") -or ($Password -eq $null -or $Password -eq ""))
        {
            Write-Error("Unable to find either user or password, please provide correct Details")
            throw new Exception("Please provide Credentails or username and password combination")
        }
        else
        {
            Write-Debug("Creating the Credentials object using user name and password")
            $encryptedPwd = ConvertTo-SecureString $Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($UserName,$encryptedPwd)
            Write-Verbose("Created the PSCredentails object for the provided user name and password")
        }
    }

    Write-Verbose("Performing Login into the azure account")
    Login-AzureRmAccount -Credential $Credential
    Write-Verbose("Getting the subscription {0} and setting the context using it" -f $SubscriptionName)
    Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Set-AzureRmContext
    Write-Verbose("Successfully set the Azure RM Context :: {0}" -f {Get-AzureRmContext})
}