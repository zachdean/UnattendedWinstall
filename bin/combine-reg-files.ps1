param (
    [string]$regFilesDir,
    [string]$outputRegFile
)

# Get list of .reg files
$regFiles = Get-ChildItem -Path $regFilesDir -Filter *.reg

# Initialize the output file
"Windows Registry Editor Version 5.00" | Out-File -FilePath $outputRegFile -Encoding ASCII

# Combine the contents of each .reg file
foreach ($regFile in $regFiles) {
    # Read the content of the .reg file
    $content = Get-Content -Path $regFile.FullName -Raw
    
    # Remove the "Windows Registry Editor Version 5.00" line
    $content = $content -replace 'Windows Registry Editor Version 5.00\r\n', ''
    
    # Append the content to the output file
    Add-Content -Path $outputRegFile -Value "`r`n$content"
}