function Remove-AzureStorageBlobFolder{
<#
    .SYNOPSIS
        This Script will remove all the files within a folder in a container in Azure Storage Blob.
    .DESCRIPTION
        This Script will remove all the files within a folder in a container in Azure Storage Blob. Given a folder location of the blob the script will remove all the files present inside that blob folder.
    .PARAMETER ContainerName
        This parameter is needed to specify the Azure Storage Container under which the blob folder to be deleted is present.
    .PARAMETER BlobName
        This parameter is needed to specify the Folder location from root within the container.
    .PARAMETER SubscriptionName
        This parameter is needed to specify the Azure Subscription Name. This can be found on the azure portal
    .PARAMETER StorageAccountName
        This parameter is needed to specify the Azure Storage Account Name. This too can be obtained from the Azure Portal
    .PARAMETER StorageAccountKey
        This parameter is needed to specify the azure storage account key. This too can be obtained from Azure Portal
    .NOTES 
        The script relies on the StartsWith function of string to filter the resources.
#>
    [CmdletBinding()]
    Param(
        [Parameter (Mandatory=$true,Position=1,HelpMessage="This parameter is needed to specify the Azure Storage Container under which the blob folder to be deleted is present.")]
        [string] $ContainerName,
        [Parameter (Mandatory=$true,Position=2,HelpMessage="This parameter is needed to specify the Folder location from root within the container.")]
        [string] $BlobName,
        [Parameter (Mandatory=$true,Position=3,HelpMessage="This parameter is needed to specify the Azure Subscription Name. This can be found on the azure portal")]
        [string] $SubscriptionName,
        [Parameter (Mandatory=$true,Position=4,HelpMessage="This parameter is needed to specify the Azure Storage Account Name. This too can be obtained from the Azure Portal")]
        [string] $StorageAccountName,
        [Parameter (Mandatory=$true,Position=5,HelpMessage="This parameter is needed to specify the azure storage account key. This too can be obtained from Azure Portal")]
        [string] $StorageAccountKey
    )
    Write-Debug "Obtaining Storage Context"
    $ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    Write-Debug "The Context obtained is :: $ctx"
    Write-Debug "Getting the blob list"
    $bloblist = Get-AzureStorageBlob -Container $containerName -Context $ctx
    Write-Debug "Processing the Blob list and removing the blobs within the folder $ContainerName"
    ForEach($blob in $bloblist)
    {
        Write-Verbose "Processing the File :: {0}" -f $blob
        if($blob.Name.StartsWith("$blobName"))
        {
            Write-Debug "Removing the file :: {0}" -f $blob
            Remove-AzureStorageBlob -Container $containerName -Context $ctx -Blob $blob.Name
        }
    }
}