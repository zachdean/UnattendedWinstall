param (
    [string]$inputFilePath = "path\to\your\file.vbs",
    [string]$savePath = "path\to\your\file.vbs",
    [int] $order = 1
)

$escapedSavePath = [System.Security.SecurityElement]::Escape($savePath)

# Read the input file
$lines = Get-Content -Path $inputFilePath

# Initialize the XML content
$xmlContent = @()

# Generate RunSynchronousCommand nodes
foreach ($line in $lines) {
    $escapedLine = [System.Security.SecurityElement]::Escape($line)
    $xmlContent += @"
<RunSynchronousCommand wcm:action="add">
    <Order>$order</Order>
    <Path>cmd.exe /c &quot;&gt;&gt;$escapedSavePath echo $escapedLine&quot;</Path>
</RunSynchronousCommand>
"@
    $order++
}

# Create a custom object to return both xmlContent and the last order
$result = [PSCustomObject]@{
    XmlContent = $xmlContent
    LastOrder = $order
}

# Echo the results to the caller
Write-Output $result