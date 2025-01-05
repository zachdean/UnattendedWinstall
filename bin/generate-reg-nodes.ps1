param (
    [string]$regFilePath,
    [int]$order = 1
)

# Read the .reg file
$regContent = Get-Content -Path $regFilePath -Raw

# Initialize the XML content array
$xmlContent = @()
$currentKey = ""

# Split the content into lines and process each line
$lines = $regContent -split "`r`n"
foreach ($line in $lines) {
    if ($line -match '^\[.*\]$') {
        # Extract the current registry key path
        $currentKey = $line.Trim('[', ']')
        continue
    }
    if ($line -match '^(.*)=(.*)$') {
        $keyValue = $matches[1].Trim()
        $data = $matches[2].Trim()

        # Determine the type and value
        if ($data -match '^dword:(.*)$') {
            $type = "REG_DWORD"
            $value = $matches[1]
        } else {
            $type = "REG_SZ"
            $value = $data
        }

        # Generate the RunSynchronousCommand node
        $xmlContent += @"
<RunSynchronousCommand wcm:action="add">
    <Order>$order</Order>
    <Path>reg.exe add "$currentKey" /v "$keyValue" /t $type /d $value /f</Path>
</RunSynchronousCommand>
"@
        $order++
    }
}

# Create a custom object to return both xmlContent and the last order
$result = [PSCustomObject]@{
    XmlContent = $xmlContent
    LastOrder = $order
}

# Output the result
return $result

# Echo the results to the caller
Write-Output $result