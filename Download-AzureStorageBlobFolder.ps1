function Download-AzureStorageBlobFolder{
<#
    .SYNOPSIS
        This Script will download all the files within a folder in a container in Azure Storage Blob.
    .DESCRIPTION
        This Script will download all the files within a folder in a container in Azure Storage Blob. Given a folder location of the blob the script will remove all the files present inside that blob folder.
    .PARAMETER ContainerName
        This parameter is needed to specify the Azure Storage Container under which the blob folder to be deleted is present.
    .PARAMETER BlobName
        This parameter is needed to specify the Folder location from root within the container.
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
        [Parameter (Mandatory=$true,Position=3,HelpMessage="This parameter is needed to specify the Azure Storage Account Name. This too can be obtained from the Azure Portal")]
        [string] $StorageAccountName,
        [Parameter (Mandatory=$true,Position=4,HelpMessage="This parameter is needed to specify the azure storage account key. This too can be obtained from Azure Portal")]
        [string] $StorageAccountKey,
        [Parameter (Mandatory=$true,Position=5,HelpMessage="This parameter is needed to specify the location on the local where to download the Azure Storage Content")]
        [string] $DestinationFolder
        #[Parameter (Mandatory=$false,Position=7,HelpMessage="this parameter is needed if you want to zip the downloaded content")]
        #[string] $ZipName
    )
    <#
        .PARAMETER DestimationFolder
        This parameter is needed to specidy the local destination folder where the data would be downloaded
    #>
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
            # Remove-AzureStorageBlob -Container $containerName -Context $ctx -Blob $blob.Name
            $relativeFolderName = $blob.Name.SubString($BlobName.Length+1)
            $localPath = Join-Path -Path $DestinationFolder -ChildPath $relativeFolderName
            $finalDestination = $localPath.Substring($localPath.LastIndexOf('/'))
            New-Item $finalDestination -ItemType Directory
            Get-AzureStorageBlobContent -Context $ctx -Container $ContainerName -Blob $blob.Name -Destination $finalDestination
        }
    }
}

function ZipFiles( $zipfilename, $sourcedir )
{
   Add-Type -Assembly System.IO.Compression.FileSystem
   $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,
        $zipfilename, $compressionLevel, $false)
}