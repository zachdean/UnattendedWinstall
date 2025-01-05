param (
    [string]$scriptFilePath = "path\to\your\file.vbs",
    [string]$scriptSavePath = "path\to\your\file.vbs",
    [int] $order = 1
)

# Read the input file
$lines = Get-Content -Path $inputFilePath

# Initialize the XML content
$xmlContent = ""

# Generate RunSynchronousCommand nodes
foreach ($line in $lines) {
    $xmlContent += @"
        <RunSynchronousCommand wcm:action="add">
            <Order>$index</Order>
            <Path>cmd.exe /c "&gt;&gt;"$scriptSavePath" echo $line</Path>
        </RunSynchronousCommand>
"@
    $index++
}

# Create a custom object to return both xmlContent and the last order
$result = [PSCustomObject]@{
    XmlContent = $xmlContent
    LastOrder = $order
}

# Echo the results to the caller
Write-Output $result