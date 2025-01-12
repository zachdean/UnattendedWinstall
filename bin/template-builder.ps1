param (
    [string]$xmlFilePath
)

# Function to process GenerateFileNodes nodes
function Process-GenerateFileNodes {
    param (
        [System.Xml.XmlElement]$node,
        [System.Xml.XmlDocument]$document,
        [int]$order      
    )
    Write-Host "Processing GenerateFileNodes node..."
    $filePath = $node.SelectSingleNode("FilePath", $namespaceManager).InnerText
    $fileSavePath = $node.SelectSingleNode("FileSavePath", $namespaceManager).InnerText
    Write-Host $order
    # Call the generate-reg-nodes.ps1 script and capture the output
    $generatedNodes = & $PSScriptRoot\generate-file-nodes.ps1 -inputFilePath $filePath -savePath $fileSavePath -order $order

    $parentNode = $node.ParentNode

    foreach ($generatedNode in $generatedNodes.XmlContent) {
        $commandNode = Create-RunSynchronousCommandNode -xmlString $generatedNode -document $document
        $parentNode.InsertBefore($commandNode, $node) | Out-Null
    }
    
    $parentNode.RemoveChild($node) | Out-Null
    $order = $generatedNodes.LastOrder
    return $order
}

# Function to process GenerateRegistryNodes nodes
function Process-GenerateRegistryNodes {
    param (
        [System.Xml.XmlElement]$node,
        [System.Xml.XmlDocument]$document,
        [int]$order
    )
    $filePath = $node.SelectSingleNode("Path", $namespaceManager).InnerText

    # Call the generate-reg-nodes.ps1 script and capture the output
    $generatedNodes = & $PSScriptRoot\generate-reg-nodes.ps1 -regFilePath $filePath -order $order

    $parentNode = $node.ParentNode
    

    foreach ($generatedNode in $generatedNodes.XmlContent) {
        $commandNode = Create-RunSynchronousCommandNode -xmlString $generatedNode -document $document
        $parentNode.InsertBefore($commandNode, $node) | Out-Null
    }
    
    $parentNode.RemoveChild($node) | Out-Null
    $order = [int]$generatedNodes.LastOrder
    return $order
}

function Process-RunSynchronousNodes {
    param (
        [System.Xml.XmlElement]$xmlContent,
        [System.Xml.XmlDocument]$document
    )

    $order = 1
    Write-Host "Processing RunSynchronous nodes..."
    
    $index = 0
    while ($index -lt $xmlContent.ChildNodes.Count) {
        $node = $xmlContent.ChildNodes[$index]
        Write-Host "Processing node: $($node.Name)" 

        switch ($node.Name) {
            "GenerateFileNodes" {
                $currentCount = $xmlContent.ChildNodes.Count
                Write-Host $order
                $order = Process-GenerateFileNodes -node $node -document $document -order $order
                $index += $xmlContent.ChildNodes.Count - $currentCount
            }
            "GenerateRegistryNodes" {
                $currentCount = $xmlContent.ChildNodes.Count
                $result = Process-GenerateRegistryNodes -node $node -document $document -order $order
                Write-Host "Order type after Process-GenerateRegistryNodes: $($result.GetType())"

                Write-Host "Order type after Process-GenerateRegistryNodes: $($result.Count)"
                $index += $xmlContent.ChildNodes.Count - $currentCount
            }
            "RunSynchronousCommand" {
                Write-Host $node.ChildNodes[0]
                $node.ChildNodes[0].InnerText = $order
                $order++
            }
            default {
            }
        }

        $index++
    }
}

function Create-RunSynchronousCommandNode {
    param (
        [string]$xmlString,
        [System.Xml.XmlDocument]$document
    )
    $wrappedXmlString = @"
        <element xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
        $xmlString
        </element>
"@

    # Load the modified string as an XML document
    $xmlContent = New-Object System.Xml.XmlDocument

    try {
        $xmlContent.LoadXml($wrappedXmlString)
    }
    catch {
        Write-Host "Error loading XML content: $wrappedXmlString"
    }


    return $document.ImportNode($xmlContent.SelectSingleNode("//RunSynchronousCommand"), $true)
}

# Function to process all nodes in the XML tree
function Process-AllNodes {
    param (
        [System.Xml.XmlElement]$xmlContent,
        [System.Xml.XmlDocument]$document
    )
    Write-Host "Processing nodes..."
    
    foreach ($node in $xmlContent.ChildNodes) {
        Write-Host "Processing node: $($node.Name)"
        if ($node.Name -eq "RunSynchronous") {
            Process-RunSynchronousNodes -xmlContent $node -document $document
        }
    }
}



# Read the XML file content into a string
$xmlString = Get-Content -Path $xmlFilePath -Raw

# Remove the <?xml ... ?> tag
$xmlString = $xmlString -replace '<\?xml.*\?>', ''

# Wrap the nodes in the <template> element with the necessary namespaces
$wrappedXmlString = @"
<template xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
$xmlString
</template>
"@

# Load the modified string as an XML document
$xmlContent = New-Object System.Xml.XmlDocument
$xmlContent.LoadXml($wrappedXmlString)

$compontent = $xmlContent.DocumentElement.FirstChild
Write-Host "XML processing started..."
Write-Host "Processing nodes..."
Write-Host $compontent.Name

# Process all nodes in the XML tree
Process-AllNodes -xmlContent $compontent  -document $xmlContent

# Return the template node
return $xmlContent.ChildNodes[0]
