param (
    [string]$templateFilePath = "./autounattend_template.xml",
    [string]$outputDirectory = "./build"
)

function Replace-FileNodes(
    [System.Xml.XmlDocument]$document,
    [System.Xml.XmlNamespaceManager]$namespaceManager
) {
    # Process each file node
    foreach ($fileNode in $templateXml.SelectNodes("//unattend:GenerateFile", $namespaceManager)) {
        $filePath = $fileNode.SelectSingleNode("unattend:FilePath", $namespaceManager).InnerText.Trim('"')
        Write-Host "Processing GenerateFile node: $filePath"
        $fileDirectory = Split-Path -Path $templateFilePath -Parent
        $targetFilePath = Join-Path -Path $fileDirectory -ChildPath $filePath
        Write-Host "Target file path: $targetFilePath"
        $fileContent = Get-Content -Path $targetFilePath -Raw

        # Replace the file node with the file content
        $parentNode = $fileNode.ParentNode
        $cdata = $templateXml.CreateCDataSection($fileContent)
        $element = $templateXml.CreateElement("File")
        
        Update-Attributes -templateNode $fileNode -importedNode $element

        $element.AppendChild($cdata) | Out-Null

        $parentNode.ReplaceChild($element, $fileNode) | Out-Null
    }
}

function Replace-TemplateNodes(
    [System.Xml.XmlDocument]$document,
    [System.Xml.XmlNamespaceManager]$namespaceManager
) {
    # Process each template node
    foreach ($templateNode in $templateXml.SelectNodes("//unattend:template", $namespaceManager)) {
        $templateFilePath = $templateNode.SelectSingleNode("unattend:Path", $namespaceManager).InnerText
        $templateOutput = & $PSScriptRoot\template-builder.ps1 -xmlFilePath $templateFilePath

        # Replace the template node with the processed XML content
        $parentNode = $templateNode.ParentNode
        $importedNode = $templateXml.ImportNode($templateOutput.ChildNodes[0], $true)

        Update-Attributes -templateNode $templateNode -importedNode $importedNode
        
        $parentNode.ReplaceChild($importedNode, $templateNode) | Out-Null

    }
}

function Update-Attributes(
    [System.Xml.XmlNode]$templateNode,
    [System.Xml.XmlElement]$importedNode
) {
    if ($templateNode.Attributes -eq $null) {
        return
    }

    if ($importedNode.Attributes -eq $null) {
        foreach ($attribute in $templateNode.Attributes) {
            $importedNode.SetAttributeNode($attribute) | Out-Null
        }

        return
    }

    # Copy attributes from the template node to the imported node
    foreach ($attribute in $templateNode.Attributes) {
        if ($importedNode.Attributes[$attribute.Name]) {
            $importedNode.Attributes[$attribute.Name].Value = $attribute.Value
        }
        else {
            $newAttribute = $templateXml.CreateAttribute($attribute.Name)
            $newAttribute.Value = $attribute.Value
            $importedNode.Attributes.Append($newAttribute) | Out-Null
        }
    }
}


# Ensure the output directory exists
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Read the XML file content into a string
$templateXmlString = Get-Content -Path $templateFilePath -Raw

# Load the XML content as an XML document
$templateXml = New-Object System.Xml.XmlDocument
$templateXml.LoadXml($templateXmlString)

# Create an XmlNamespaceManager and add the namespaces
$namespaceManager = New-Object System.Xml.XmlNamespaceManager($templateXml.NameTable)
$namespaceManager.AddNamespace("unattend", "urn:schemas-microsoft-com:unattend")
$namespaceManager.AddNamespace("wcm", "http://schemas.microsoft.com/WMIConfig/2002/State")

Replace-TemplateNodes -document $templateXml -namespaceManager $namespaceManager
Replace-FileNodes -document $templateXml -namespaceManager $namespaceManager

# Save the modified content to the output directory
$outputFilePath = Join-Path -Path $outputDirectory -ChildPath "autounattend.xml"
$templateXml.Save($outputFilePath)

# Read the modified XML content into a string
$modifiedXmlString = Get-Content -Path $outputFilePath -Raw

# Replace `xmls=""` with an empty string
$modifiedXmlString = $modifiedXmlString -replace ' xmlns=""', ''

# Save the modified content back to the output file
Set-Content -Path $outputFilePath -Value $modifiedXmlString

Write-Host "XML processing completed and saved to $outputFilePath"
