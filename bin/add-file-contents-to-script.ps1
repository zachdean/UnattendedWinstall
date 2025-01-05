param (
    [string]$filesPath,
    [string]$targetFilePath,
    [string]$saveFilePath
)

# Function to perform string replace
function Replace-StringInFile {
    param (
        [string]$filePath,
        [string]$pattern,
        [string]$replacement
    )

    (Get-Content -Path $filePath) -replace $pattern, $replacement | Set-Content -Path $filePath
}

# Extract the directory from the target file path
$buildDir = Split-Path -Path $saveFilePath -Parent
Write-Host "Build directory: $buildDir"
if (-Not (Test-Path -Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir
}

# Get list of files
$regFiles = Get-ChildItem -Path $filesPath

# Read the target file content
$targetFileContent = Get-Content -Path $targetFilePath -Raw

# Perform string replace for each file
foreach ($regFile in $regFiles) {
    Write-Host "Processing file: $regFile"
    $fileName = $regFile.Name
    $pattern = "~~$fileName~~"
    Write-Host "Pattern: $pattern"
    $replacement = Get-Content -Path $regFile.FullName -Raw
    Write-Host "Replacement: $replacement"

    # Replace the pattern with the content of the file
    $targetFileContent = $targetFileContent -replace [regex]::Escape($pattern), $replacement
}

# Save the modified content to the specified location
Set-Content -Path $saveFilePath -Value $targetFileContent

Write-Host "String replacement completed and saved to $saveFilePath"