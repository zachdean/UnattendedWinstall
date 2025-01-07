param (
    [string]$templateFilePath = "./autounattend_template.xml",
    [string]$outputDirectory = "./build"
)

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

# Process each template node
foreach ($templateNode in $templateXml.SelectNodes("//unattend:template", $namespaceManager)) {
    $templateFilePath = $templateNode.SelectSingleNode("unattend:Path", $namespaceManager).InnerText
    $templateOutput = & .\bin\template-builder.ps1 -xmlFilePath $templateFilePath

    # Replace the template node with the processed XML content
    $parentNode = $templateNode.ParentNode
    $importedNode = $templateXml.ImportNode($templateOutput, $true)
    Write-Host $importedNode.Name
    $parentNode.ReplaceChild($importedNode, $templateNode) | Out-Null
}

# Save the modified content to the output directory
$outputFilePath = Join-Path -Path $outputDirectory -ChildPath "autounattend.xml"
$templateXml.Save($outputFilePath)

Write-Host "XML processing completed and saved to $outputFilePath"
