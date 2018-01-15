[CmdletBinding()]
Param(
[Parameter (Mandatory=$true,Position=1)]
[string] $dbName
[Parameter (Mandatory=$true,Position=2)]
[string] $serverInstance
[Parameter (Mandatory=$true,Position=3)]
[string] $dbUserName
[Parameter (Mandatory=$true,Position=4)]
[string] $dbPassword
[Parameter (Mandatory=$true,Position=5)]
[string] $sqlFileLocation
[Parameter (Mandatory=$false,Position=6)]
[string] $sqlErrorFileLocation
)
Invoke-Sqlcmd -Database $dbName -InputFile $sqlFileLocation -OutputSqlErrors $sqlErrorFileLocation -Password $dbPassword -ServerInstance $serverInstance -Username $dbUserName