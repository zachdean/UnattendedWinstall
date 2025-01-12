param (
    [string]$registryTemplatesDirectory
)

$buildDir = "$PSScriptRoot\..\build\registry"
if (-Not (Test-Path -Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir
}

$directories = Get-ChildItem -Path $registryTemplatesDirectory

foreach ($dir in $directories) {
    $regFiles = Get-ChildItem -Path $dir.FullName -Filter *.reg

    if ($regFiles.Count -eq 1 -and $regFiles[0].Name -eq "default.reg") {
        $newFileName = ($dir.Name -replace '-', '_').ToLower()
        $newFileName = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($newFileName) + ".reg"
        Copy-Item -Path $regFiles[0].FullName -Destination (Join-Path -Path $buildDir -ChildPath $newFileName) | Out-Null
    } elseif ($regFiles.Count -gt 1) {
        $outputRegFile = (Join-Path -Path $buildDir -ChildPath (($dir.Name -replace '-', '_').ToLower()))
        $outputRegFile = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($outputRegFile) + ".reg"
        & $PSScriptRoot\combine-reg-files.ps1 -regFilesDir $dir.FullName -outputRegFile $outputRegFile | Out-Null
    }
}
