function Set-MyAzureFirewallRule {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,Position=1)]
        [string] $sqlServerName
    )
    $response = Invoke-WebRequest ifconfig.me/ip
    $ip = $response.Content.Trim()
    $ruleName =  -join ($env:computername.Trim(),"_dongle")
    Write-Host "Hello"
}

function Rest-PostAPITest {
    $url = "https://reqres.in/api/users?page=2"

	$name = "morpheus"
	$job = "leader"
		
	$messageBody = @{
		name = $name
		job = $job
	}
	
	$user = 'bhansm'
	$pass = 'Mitz@#23mit'

	$pair = "$($user):$($pass)"
	Write-Host "$pair"
	#$cred = Get-Credential
	$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pair))
	
	$basicAuthValue = "Basic $encodedCreds"

	$Headers = @{
		Authorization = $basicAuthValue
	}
#https://stackoverflow.com/questions/20471486/how-can-i-make-invoke-restmethod-use-the-default-web-proxy	
	$proxyUri = [Uri]$null
	$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
	$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
	$proxyUri = $proxy.GetProxy("$url")
	
	$result = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body (ConvertTo-Json $messageBody) -ContentType "application/json" -UseDefaultCredentials -Proxy $proxyUri -ProxyUseDefaultCredentials
	
	
	Write-Host $result
}

function Update-MyAzureFirewallRule{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,Position=1)]
        [string] $sqlServerName
    )
    $response = Invoke-WebRequest ifconfig.me/ip
    $ip = $response.Content.Trim()
    $ruleName =  -join ($env:computername.Trim(),"_dongle")
    Set-AzureSqlDatabaseServerFirewallRule -StartIPAddress $ip -EndIPAddress $ip -RuleName $ruleName -ServerName $sqlServerName
}

function Remove-MyAzureFirewallRule{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,Position=1)]
        [string] $sqlServerName
    )
    $ruleName =  -join ($env:computername.Trim(),"_dongle")
    Remove-AzureSqlDatabaseServerFirewallRule -RuleName $ruleName -ServerName $sqlServerName
}

function Get-MyAzureFirewallRule{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,Position=1)]
        [string] $sqlServerName
    )
    $ruleName =  -join ($env:computername.Trim(),"_dongle")
    Get-AzureSqlDatabaseServerFirewallRule -RuleName $ruleName -ServerName $sqlServerName
}