### Microsoft Learning course 55247A
### Use Azure CLI to create Resource Group, Storage Account and Blob / File Shares.  
### Use an Administrator PowerShell Console to run the script or to run the code line by line.
### Create Variables
$WorkFolder = "C:\Labfiles\"
$Initials = "in"
$NamePrefix = $Initials.ToLower() + "55247a" + (Get-Date -Format "mmss") 
$ResourceGroupName = $NamePrefix + "rg"
$Location = "EASTUS"
$StorageAccountName = $NamePrefix + "sa"
$BlobContainerName = "55247a"

### Add AZ Interactive Module   (Not Required)
### az component update --add interactive
### az interactive

### Login to Azure.  You will be prompted to use a web browser to enter an authentication code at https://aka.ms/devicelogin
# az login
	        
### List existing Resource Groups and create a new one
az group list
az group create -n $ResourceGroupName -l $Location

### Create a Storage Account       (Note:  The az storage account check-name command can be used to verify that no one else is using a storage account name.)
az storage account create -n $StorageAccountName -l $Location -g $ResourceGroupName --sku standard_lrs          
$StorageAccount = az storage account list -g $ResourceGroupName | ConvertFrom-Json
$StorageAccountKey = az storage account keys list -g $ResourceGroupName -n $StorageAccountName | ConvertFrom-Json
$StorageAccountCS = $((az storage account show-connection-string -n $StorageAccountName -g $ResourceGroupName) | ConvertFrom-Json).ConnectionString

# Create Blob and File Share
az storage container create -n $BlobContainerName --connection-string $StorageAccountCS
$BlobShare = az storage container list --account-key $StorageAccountKey[0].Value --account-name $StorageAccountName | ConvertFrom-Json
az storage share create --name $BlobContainerName --connection-string $StorageAccountCS
$FileShare = az storage share list --account-key $StorageAccountKey[0].Value --account-name $StorageAccountName | ConvertFrom-Json

### Upload data to the Blob and File Share
az storage blob upload-batch --source $WorkFolder --pattern "*.zip" --destination $BlobContainerName --connection-string $StorageAccountCS
az storage file upload-batch --source $WorkFolder --pattern "*.ps1" --destination $BlobContainerName --connection-string $StorageAccountCS

# Connect to File Share
Test-NetConnection -ComputerName ([System.Uri]::new($StorageAccount.PrimaryEndpoints.File).Host) -Port 445
$ComputerName = $StorageAccountName + ".file.core.windows.net"
$ShareName = "\\" + $ComputerName + "\" + $FileShare.Name
New-PSDrive -Name Z -PSProvider FileSystem -Root $ShareName -Credential $Credential -Persist
# Remove-PSDrive -Name Z

### Use the Azure Portal to verify the create of the new resource group, storage account, and container.
### Delete the resource group and verify that the storage account and container were also removed:  
# az group delete -n $ResourceGroupName

