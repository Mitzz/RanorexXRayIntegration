[CmdletBinding()]
Param(
[Parameter (Mandatory=$true,Position=1)]
[string]$storageAccountName,

[Parameter (Mandatory=$true,Position=2)]
[string]$storageAccountKey,

[Parameter (Mandatory=$true,Position=3)]
[string]$containerName,

[Parameter (Mandatory=$true,Position=4)]
[string]$blobName
)


$ctx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Remove-AzureStorageBlob -Blob $blobName -Container $containerName -Context $ctx