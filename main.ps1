$jsonFilePath = ".\params.json"
$jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

$accessKey = $jsonContent.accessKey
$secretKey = $jsonContent.secretKey
$region = $jsonContent.region
$bucketName = $jsonContent.bucketName
$filePathList = $jsonContent.filePathList

Import-Module AWS.Tools.Installer
Set-AWSCredential -AccessKey $accessKey -SecretKey $secretKey -StoreAs default
Initialize-AWSDefaults -ProfileName default -Region $region

foreach ($filePath in $filePathList) {
    if (-not (Test-Path -Path $filePath)) {
        Write-Host "File not found: $filePath" -ForegroundColor Red
        continue
    }

    try {
        Write-Host "Uploading file $filePath to bucket $bucketName" -ForegroundColor Yellow
        Write-S3Object -BucketName $bucketName -File $filePath -Key (Split-Path $filePath -Leaf) -CannedACLName private -ProfileName default
    }
    catch {
        Write-Host "Error when performing multipart upload to file: $filePath. Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}