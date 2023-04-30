$jsonFilePath = ".\params.json"
$jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

$accessKey = $jsonContent.accessKey
$secretKey = $jsonContent.secretKey
$region = $jsonContent.region
$bucketName = $jsonContent.bucketName
$pathsList = $jsonContent.pathsList

Import-Module AWS.Tools.Installer
Set-AWSCredential -AccessKey $accessKey -SecretKey $secretKey -StoreAs default
Initialize-AWSDefaults -ProfileName default -Region $region

foreach ($path in $pathsList) {
    if (-not (Test-Path -Path $path)) {
        Write-Host "Path not found: $path" -ForegroundColor Red
        continue
    }

    if (Test-Path -Path $path -PathType Container) {
        try {
            Write-Host "Uploading folder $path to bucket $bucketName" -ForegroundColor Yellow
            $folderName = Split-Path $path -Leaf
            Get-ChildItem $path -Recurse | ForEach-Object {
                $relativePath = $_.FullName.Substring($path.Length).TrimStart('\')
                $key = (Join-Path $folderName $relativePath).Replace('\', '/')
                Write-S3Object -BucketName $bucketName -File $_.FullName -Key $key -CannedACLName private -ProfileName default
            }
        }
        catch {
            Write-Host Error when uploading directory: $path. Erro: $($_.Exception.Message)" -ForegroundColor Red
        }
    } elseif (Test-Path -Path $path -PathType Leaf) {
        try {
            Write-Host "Uploading file $path to bucket $bucketName" -ForegroundColor Yellow
            Write-S3Object -BucketName $bucketName -File $path -Key (Split-Path $path -Leaf) -CannedACLName private -ProfileName default
        }
        catch {
            Write-Host "Error when uploading file: $path. Erro: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
