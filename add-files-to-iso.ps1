param (
    [string]$isoPath = "path\to\your\original.iso",
    [string]$tempDir = "path\to\temp\directory",
    [string]$newIsoPath = "path\to\your\new.iso",
    [string]$newFilesDir = "path\to\new\files"
)

# Mount the ISO
$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter

# Copy contents to temporary directory
Copy-Item -Path "$driveLetter\*" -Destination $tempDir -Recurse

# Dismount the ISO
Dismount-DiskImage -ImagePath $isoPath

# Add new files to the temporary directory
Copy-Item -Path "$newFilesDir\*" -Destination $tempDir -Recurse

# Create a new ISO with the updated contents
$isoScript = @"
$sourcePath = '$tempDir'
$destinationPath = '$newIsoPath'
$bootImage = '$tempDir\boot\etfsboot.com'
$oscdimg = 'path\to\oscdimg.exe'

& $oscdimg -b$bootImage -u2 -h -m -o -lNEW_ISO_LABEL $sourcePath $destinationPath
"@

Invoke-Expression $isoScript

# Clean up temporary directory if needed
# Remove-Item -Path $tempDir -Recurse
