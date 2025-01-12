param (
    [string]$outputDirectory = "./build"
)
$registryFilesBuildDirectory = "$PSScriptRoot\..\build\registry"

Write-Host "Building autounattend.xml"
Write-Host "Output directory: $outputDirectory"
Write-Host "Current file location: $PSScriptRoot"

$currentFileLocation = $PSScriptRoot
Write-Output "The current file location is: $currentFileLocation"

# Create Registry Files
$registryFileDirectory = "$PSScriptRoot\..\registry\"


& "$PSScriptRoot\process-registry-directories.ps1" -registryTemplatesDirectory $registryFileDirectory

# process script files
$scriptFileDirectory = "$PSScriptRoot\..\script-templates"

$templateFiles = Get-ChildItem -Path $scriptFileDirectory -File

foreach ($file in $templateFiles) {
    $fileName = $file.Name
    Write-Output "Processing file: $fileName"
    $saveFilePath = "$PSScriptRoot\..\build\files\$fileName"
    & "$PSScriptRoot\add-file-contents-to-script.ps1" $registryFilesBuildDirectory $file.FullName $saveFilePath
}

# build autounattend.xml
& "$PSScriptRoot\autounnatted-builder.ps1" -templateFilePath "$PSScriptRoot\..\autounattend_template.xml" -outputDirectory "$outputDirectory"