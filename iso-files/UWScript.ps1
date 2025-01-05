      # Check if script is running as Administrator
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Try {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit
    }
    Catch {
        Write-Host "Failed to run as Administrator. Please rerun with elevated privileges."
        Exit
    }
}

# Set window title and color scheme
$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"
Clear-Host

# Center the PowerShell window
$psWindow = Get-Process -Id $pid | ForEach-Object { $_.MainWindowHandle }
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WindowCentering {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public static void CenterWindow(IntPtr hWnd) {
        RECT rect;
        GetWindowRect(hWnd, out rect);
        int windowWidth = rect.Right - rect.Left;
        int windowHeight = rect.Bottom - rect.Top;
        
        int screenWidth = GetSystemMetrics(0);
        int screenHeight = GetSystemMetrics(1);
        
        int x = (screenWidth / 2) - (windowWidth / 2);
        int y = (screenHeight / 2) - (windowHeight / 2);

        MoveWindow(hWnd, x, y, windowWidth, windowHeight, true);
    }

    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);
}
"@

[WindowCentering]::CenterWindow($psWindow)

# START OF MENU FUNCTIONS
$script:loop = $true

# Header
function Show-Header {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "                  UWScript                  " -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host "NO LIABILITY ACCEPTED, PROCEED WITH CAUTION!" -ForegroundColor Black -BackgroundColor Red
    Write-Host ""
}

# Main Menu
function Show-MainMenu {
    Show-Header
    Write-Host "Main Menu:" -ForegroundColor Yellow
    Write-Host "1. Software & Apps"
    Write-Host "2. Privacy & Security"
    Write-Host "3. Windows Updates"
    Write-Host "4. Optimize Registry"
    Write-Host "5. Tasks & Services"
    Write-Host "6. Power Settings"
    Write-Host "0. Exit"
    
    $choice = Read-Host "Select an option (0-6)"

    switch ($choice) {
        "1" { Show-SoftwareMenu }      # Call the Software & Apps menu
        "2" { Show-PrivacySecurityMenu } # Call the Privacy & Security menu
        "3" { Show-WindowsUpdateMenu }  # Call the Windows Updates menu
        "4" { Show-OptimizeRegistryMenu } # Call the Optimize Registry menu
        "5" { Show-TasksServicesMenu } # Call the Tasks & Services menu
        "6" { Show-PowerSettingsMenu } # Call the Power Settings menu
        "0" { $script:loop = $false }  # Exit
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

# Reusable Menu Function
function Show-Menu {
    param (
        [string]$menuTitle,
        [string[]]$options,
        [hashtable]$actions,
        [string]$instructions = "Select an option",
        [switch]$showHeader
    )

    # Display the header if specified
    if ($showHeader) {
        Show-Header
    }

    # Display the menu title
    Write-Host "$menuTitle" -ForegroundColor Yellow

    # Display the "Back" option as "0"
    Write-Host "0. Main Menu" -ForegroundColor Cyan

    # Display the options starting from 1
    for ($i = 0; $i -lt $options.Length; $i++) {
        Write-Host "$($i + 1). $($options[$i])"
    }

    Write-Host ""
    $choice = Read-Host "$instructions"

    if ($choice -eq "0") {
        return # Return to the previous menu or exit current menu
    }
    elseif ($actions.ContainsKey($choice)) {
        # Execute the corresponding action
        & $actions[$choice]
    }
    else {
        Write-Host "Invalid choice. Try again." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Show-Menu -menuTitle $menuTitle -options $options -actions $actions -showHeader:$showHeader
    }
}


# 1. Software & Apps Menu
function Show-SoftwareMenu {
    Show-Menu -menuTitle "Software & Apps" `
        -options @("Install Software", "Remove Bloatware Apps") `
        -actions @{
        "1" = { Show-AppInstallMenu }
        "2" = { Show-AppRemovalMenu }
    } `
        -showHeader
}

# Install Software Menu
function Show-AppInstallMenu {
    Show-Menu -menuTitle "Select an app to install" `
        -options @("Microsoft Store", "Browser Menu", "UniGetUI (Software Manager)") `
        -actions @{
        "1" = { Install-Store }
        "2" = { Show-BrowserInstallMenu }
        "3" = { Install-AppWithWinGet -AppName "MartiCliment.UniGetUI" -FriendlyName "UniGetUI (Software Manager)" }
    } `
        -showHeader
}
function Show-BrowserInstallMenu {
    Show-Menu -menuTitle "Select a Browser to install" `
        -options @("Thorium Browser", "Mozilla Firefox", "Microsoft Edge", "Google Chrome", "Brave Browser") `
        -actions @{
        "1" = { Install-AppWithWinGet -AppName "Alex313031.Thorium" -FriendlyName "Thorium Browser" } 
        "2" = { Install-AppWithWinGet -AppName "Mozilla.Firefox" -FriendlyName "Mozilla Firefox" }
        "3" = { Install-AppWithWinGet -AppName "Microsoft.Edge" -FriendlyName "Microsoft Edge" }
        "4" = { Install-AppWithWinGet -AppName "Google.Chrome" -FriendlyName "Google Chrome" }
        "5" = { Install-AppWithWinGet -AppName "Brave.Brave" -FriendlyName "Brave Browser" }  
    } `
        -showHeader
}

# Remove Bloatware Apps Menu
function Show-AppRemovalMenu {
    Show-Menu -menuTitle "Remove Windows Bloatware Apps" `
        -options @("Remove ALL Windows Apps") `
        -actions @{
        "1" = { Remove-Apps }
    } `
        -showHeader
}

# 2. Privacy & Security Menu
function Show-PrivacySecurityMenu {
    Show-Menu -menuTitle "Privacy & Security" `
        -options @("Check Windows Defender Status", "Check User Account Control Status", "Apply Recommended Privacy Settings", "Apply Windows Default Privacy Settings") `
        -actions @{
        "1" = { Get-WindowsDefenderStatus }
        "2" = { Get-UACStatus }
        "3" = { Set-RecommendedPrivacySettings }
        "4" = { Set-DefaultPrivacySettings }
    } `
        -showHeader
}

# 3. Windows Updates Menu
function Show-WindowsUpdateMenu {
    Show-Menu -menuTitle "Windows Update Settings" `
        -options @("Set Recommended Update Settings", "Set Default Update Settings") `
        -actions @{
        "1" = { Set-RecommendedUpdateSettings }
        "2" = { Set-DefaultUpdateSettings }
    } `
        -showHeader
}

# 4. Optimize Registry Menu
function Show-OptimizeRegistryMenu {
    Show-Menu -menuTitle "Optimize Windows Registry" `
        -options @("Set Recommended Registry Settings", "Set Default Registry Settings") `
        -actions @{
        "1" = { Set-RecommendedHKLMRegistry; Set-RecommendedHKCURegistry }
        "2" = { Set-DefaultHKLMRegistry; Set-DefaultHKCURegistry }
    } `
        -showHeader
}

# 5. Tasks & Services Menu
function Show-TasksServicesMenu {
    Show-Menu -menuTitle "Windows Services & Scheduled Tasks" `
        -options @("Minimal Services", "Default Services", "Disable Scheduled Tasks", "Enable Scheduled Tasks") `
        -actions @{
        "1" = { Set-ServiceStartup }
        "2" = { Set-DefaultServices }
        "3" = { Disable-ScheduledTasks }
        "4" = { Enable-ScheduledTasks }
    } `
        -showHeader
}

# 6. Power Settings Menu
function Show-PowerSettingsMenu {
    Show-Menu -menuTitle "Power Settings" `
        -options @("Recommended Power Settings", "Default Power Settings") `
        -actions @{
        "1" = { Set-RecommendedPowerSettings }
        "2" = { Set-DefaultPowerSettings }
    } `
        -showHeader
}

# END OF MENU FUNCTIONS

# Define Unattended Windows Installation Variables & Functions
# Check if the marker file exists to determine if we are in the specialize phase
$markerFilePath = "C:\specialize_marker.txt"
$isSpecializePhase = Test-Path $markerFilePath
# Function to Pause scripts only when not in Specialize Phase
function Wait-IfNotSpecialize {
    if (-not $isSpecializePhase) {
        Pause
    }
}

# START OF COMMAND & OPERATION FUNCTIONS
# Start of Software & Apps Functions
# Install Software Functions

# Check for internet connection
function Test-InternetConnection {
    Try {
        $connection = Test-Connection -ComputerName www.microsoft.com -Count 1 -ErrorAction Stop
        if ($connection) {
            return $true
        }
    }
    Catch {
        return $false
    }
}

# Install the Microsoft Store
function Install-Store {
    Clear-Host
    # Check for internet connection
    if (-not (Test-InternetConnection)) {
        Write-Host "No internet connection detected. Please connect to the internet and try again." -BackgroundColor Red
        Wait-IfNotSpecialize
        return
    }

    # If internet connection is available, continue with installation
    Show-Header
    Write-Host "Installing Microsoft Store . . ."
    Try {
        wsreset -i -ErrorAction SilentlyContinue
        Show-Header
        Write-Host "Microsoft Store is being installed silently in the background." -BackgroundColor Green
        Write-Host "Please allow a few minutes for it to install and use it to reinstall the necessary apps manually."
    }
    Catch {
        Show-Header
        Write-Host "An error occurred while trying to install the Microsoft Store. Please try again later." -BackgroundColor Red
    }
    Wait-IfNotSpecialize
}

# Function to check if WinGet is installed, install if necessary, and check for updates
function Test-WinGetStatus {
    # Helper function to check if WinGet is installed
    function Test-WinGetInstalled {
        Try {
            winget --version | Out-Null
            return $true
        }
        Catch {
            return $false
        }
    }

    # Helper function to install required dependencies from GitHub
    function Install-WinGetDependencies {
        Show-Header
        Write-Host "Installing required dependencies, please wait . . ." -ForegroundColor Yellow

        # Define the URLs and paths for dependencies
        $dependencyUrls = @(
            @{Url = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"; Path = "$env:TEMP\Microsoft.UI.Xaml.2.8.appx" },
            @{Url = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"; Path = "$env:TEMP\Microsoft.VCLibs.140.00.UWPDesktop.x64.appx" }
        )

        # Download and install each dependency
        foreach ($dependency in $dependencyUrls) {
            Try {
                Start-BitsTransfer -Source $dependency.Url -Destination $dependency.Path -TransferType Download -ErrorAction Stop | Out-Null
                Show-Header
                Try {
                    Add-AppxPackage -Path $dependency.Path
                    Show-Header
                }
                Catch {
                    Write-Host "Failed to install $($dependency.Path). Please install it manually from the URL: $($dependency.Url)" -ForegroundColor Red
                    Wait-IfNotSpecialize
                    Exit
                }
            }
            Catch {
                Write-Host "Failed to download $($dependency.Path). Check your internet connection and try again." -ForegroundColor Red
                Wait-IfNotSpecialize
                Exit
            }
        }
    }

    # Function to install WinGet from GitHub if not found
    function Install-WinGet {
        Show-Header
        Write-Host "WinGet is not installed. Downloading the latest version from GitHub..." -ForegroundColor Yellow

        # Ensure internet connection is active
        if (-not (Test-InternetConnection)) {
            Show-Header
            Write-Host "No internet connection detected. Please connect to the internet and try again." -ForegroundColor Red
            Wait-IfNotSpecialize
            Exit
        }

        # Install the required dependencies
        Show-Header
        Install-WinGetDependencies

        # Define GitHub URL for WinGet releases
        $wingetDownloadUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $wingetInstallerPath = "$env:TEMP\WinGetInstaller.msixbundle"

        Try {
            Show-Header
            Write-Host "Starting download of WinGet installer using BITS..."

            Start-BitsTransfer -Source $wingetDownloadUrl -Destination $wingetInstallerPath -TransferType Download -ErrorAction Stop | Out-Null

            # Confirm the file was downloaded successfully
            if (-not (Test-Path $wingetInstallerPath) -or (Get-Item $wingetInstallerPath).Length -eq 0) {
                Show-Header
                Write-Host "The download failed or the file is empty. Please try downloading manually from: $wingetDownloadUrl" -ForegroundColor Red
                Wait-IfNotSpecialize
                Exit
            }

            Show-Header
            Write-Host "WinGet installer downloaded successfully."

            # Install the downloaded WinGet installer
            Try {
                Add-AppxPackage -Path $wingetInstallerPath
                Show-Header
                Write-Host "WinGet installed successfully." -ForegroundColor Green
            }
            Catch {
                Show-Header
                Write-Host "Failed to install WinGet. Please install it manually from the GitHub page: https://github.com/microsoft/winget-cli/releases" -ForegroundColor Red
                Wait-IfNotSpecialize
                Exit
            }
        }
        Catch {
            Show-Header
            Write-Host "Failed to download the WinGet installer. Check your internet connection and try again." -ForegroundColor Red
            Wait-IfNotSpecialize
            Exit
        }
    }

    # Check if WinGet is installed, if not, install it
    if (-not (Test-WinGetInstalled)) {
        Install-WinGet
    }

    # Once installed, check for updates
    Show-Header
    Write-Host "Checking for WinGet updates..."
    Try {
        $updateCheck = winget upgrade --id Microsoft.WinGet -e --accept-package-agreements --accept-source-agreements 2>&1
        if ($updateCheck -match "No installed package found" -or $updateCheck -match "No applicable upgrade found") {
            Show-Header
            Write-Host "WinGet is already up-to-date." -ForegroundColor Green
        }
        elseif ($updateCheck -match "An applicable upgrade is available") {
            # Perform the upgrade if available
            Show-Header
            Write-Host "An update is available for WinGet. Upgrading now..."
            Try {
                winget upgrade --id Microsoft.WinGet -e --accept-package-agreements --accept-source-agreements | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Show-Header
                    Write-Host "WinGet updated successfully." -ForegroundColor Green
                }
                else {
                    Show-Header
                    Write-Host "Failed to update WinGet. Proceeding with app installation..." -ForegroundColor Yellow
                }
            }
            Catch {
                Show-Header
                Write-Host "An error occurred while upgrading WinGet. Proceeding with app installation..." -ForegroundColor Yellow
            }
        }
        else {
            Show-Header
            Write-Host "Could not determine WinGet update status. Proceeding with app installation..." -ForegroundColor Yellow
        }
    }
    Catch {
        Show-Header
        Write-Host "An error occurred while checking for WinGet updates. Proceeding with app installation..." -ForegroundColor Yellow
    }
}

# Function to install an app using WinGet
function Install-AppWithWinGet {
    param (
        [string]$AppName,
        [string]$FriendlyName
    )

    Show-Header

    # Check for internet connection
    if (-not (Test-InternetConnection)) {
        Show-Header
        Write-Host "No internet connection detected. Please connect to the internet and try again." -BackgroundColor Red
        Wait-IfNotSpecialize
        return
    }

    # Update WinGet to ensure it's the latest version
    Show-Header
    Test-WinGetStatus

    # Continue with app installation
    Show-Header
    Write-Host "Installing $FriendlyName using WinGet . . ."
    Try {
        # Attempt to install or upgrade the app using WinGet
        $installOutput = winget install --id $AppName -e --silent --accept-package-agreements --accept-source-agreements 2>&1

        if ($installOutput -match "Found an existing package already installed" -and $installOutput -match "No available upgrade found") {
            Write-Host "$FriendlyName is already installed and up-to-date." -BackgroundColor Green
        }
        elseif ($installOutput -match "Successfully installed") {
            Show-Header
            Write-Host "$FriendlyName installation completed successfully." -BackgroundColor Green
        }
        elseif ($installOutput -match "No package found") {
            Show-Header
            Write-Host "Failed to install $FriendlyName using ID '$AppName'. Package not found or check your internet connection." -BackgroundColor Red
        }
        else {
            Show-Header
            Write-Host "An issue occurred during the installation of $FriendlyName. Please check the app ID or try again later." -BackgroundColor Red
        }
    }
    Catch {
        Show-Header
        Write-Host "An unexpected error occurred while installing $FriendlyName." -BackgroundColor Red
    }
    Wait-IfNotSpecialize
}

# Remove Bloatware Apps Functions
# Define Packages
$appxPackages = @(
    'Microsoft.Microsoft3DViewer', 'Microsoft.BingSearch', 'Microsoft.WindowsCamera', 'Clipchamp.Clipchamp',
    'Microsoft.WindowsAlarms', 'Microsoft.549981C3F5F10', 'Microsoft.Windows.DevHome',
    'MicrosoftCorporationII.MicrosoftFamily', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp',
    'microsoft.windowscommunicationsapps', 'Microsoft.WindowsMaps', 'Microsoft.ZuneVideo',
    'Microsoft.BingNews', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.Office.OneNote',
    'Microsoft.OutlookForWindows', 'Microsoft.People', 'Microsoft.Windows.Photos',
    'Microsoft.PowerAutomateDesktop', 'MicrosoftCorporationII.QuickAssist', 'Microsoft.SkypeApp',
    'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'MSTeams',
    'Microsoft.Getstarted', 'Microsoft.Todos', 'Microsoft.WindowsSoundRecorder', 'Microsoft.BingWeather',
    'Microsoft.ZuneMusic', 'Microsoft.WindowsTerminal', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxApp',
    'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.GamingApp', 'Microsoft.YourPhone', 'Microsoft.OneDrive',
    'Microsoft.549981C3F5F10', 'Microsoft.MixedReality.Portal', 'Microsoft.ScreenSketch'
    'Microsoft.Windows.Ai.Copilot.Provider', 'Microsoft.Copilot', 'Microsoft.Copilot_8wekyb3d8bbwe',
    'Microsoft.WindowsMeetNow', 'Microsoft.WindowsStore', 'Microsoft.Paint', 'Microsoft.MSPaint'
)

# Define Windows Capabilities
$capabilities = @(
    'MathRecognizer', 'OpenSSH.Client',
    'Microsoft.Windows.PowerShell.ISE', 'App.Support.QuickAssist', 'App.StepsRecorder',
    'Media.WindowsMediaPlayer', 'Microsoft.Windows.WordPad', 'Microsoft.Windows.MSPaint'
)

# Apply registry mods to prevent reinstallation and disable features
function Set-AppsRegistry {
    $MultilineComment = @"
%%Windows_Apps.reg%%
"@
    Set-Registry "$MultilineComment"
}

# Removes OneDrive during Windows Installation
function Remove-OneDrive {
    Remove-Item "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.exe" -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\OneDriveSetup.exe" -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SysWOW64\OneDriveSetup.exe" -ErrorAction SilentlyContinue
}

# Uninstalls OneDrive in existing Windows Installation
function Uninstall-OneDrive {
    # stop onedrive running
    Stop-Process -Force -Name OneDrive -ErrorAction SilentlyContinue | Out-Null
    # uninstall onedrive w10
    cmd /c "C:\Windows\SysWOW64\OneDriveSetup.exe -uninstall >nul 2>&1"
    # clean onedrive w10 
    Get-ScheduledTask | Where-Object { $_.Taskname -match 'OneDrive' } | Unregister-ScheduledTask -Confirm:$false
    # uninstall onedrive w11
    cmd /c "C:\Windows\System32\OneDriveSetup.exe -uninstall >nul 2>&1"
}

# Disables Recall
function Disable-Recall {
    Dism /Online /Disable-Feature /Featurename:Recall /NoRestart | Out-Null
}

# Remove All Bloatware (UWP) Apps from Windows.
function Remove-Apps {
    Show-Header
    Write-Host "Are You Sure You Want to Remove ALL Windows Apps? (Y/N)" -ForegroundColor Black -Backgroundcolor Yellow
    Write-Host "Includes: OneDrive, Teams, Outlook for Windows and more . . ." -ForegroundColor Black -Backgroundcolor Yellow
    Write-Host "(CAUTION! Can't be Undone!)" -BackgroundColor Red
    $confirmation = Read-Host "Enter your choice"

    if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
        Show-Header
        Write-Host "Removing Pre-installed Apps and Features. Please wait . . ."
        # Bloatware Apps
        Get-AppxPackage -AllUsers |
        Where-Object { $appxPackages -contains $_.Name } |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-Null
        # Legacy Windows Features & Apps
        Get-WindowsCapability -Online |
        Where-Object { $capabilities -contains ($_.Name -split '~')[0] } |
        Remove-WindowsCapability -Online -ErrorAction SilentlyContinue | Out-Null
        # Calls specified functions
        Show-Header
        Set-AppsRegistry
        Uninstall-OneDrive
        Show-Header
        Disable-Recall
        Show-Header
        Write-Host "Pre-installed Apps and Features removed successfully." -BackgroundColor Green
        Wait-IfNotSpecialize
    }
    else {
        Show-MainMenu
    }
}
# End of Software & Apps Functions

# Start of Privacy & Security Functions
# Check if Windows Defender is Enabled or Disabled
function Get-WindowsDefenderStatus {
    Clear-Host
    $defenderKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Sense"
    $defenderStatus = (Get-ItemProperty -Path $defenderKey -Name Start).Start

    if ($defenderStatus -eq 4) {
        Show-Header
        Write-Host "Windows Defender is permanently disabled." -ForegroundColor Red
        Write-Host "Press 1 to enable Windows Defender."
        Write-Host "Note: Enabling Defender using this script means it cannot be permanently disabled again without reinstalling Windows with the UnattendedWinstall XML file."
        
        $choice = Read-Host "Enter your choice (1 to enable, any other key to cancel)"
        
        if ($choice -eq '1') {
            $confirm = Read-Host "Are you sure you want to enable Windows Defender? (y/n)"
            if ($confirm -eq 'y') {
                Enable-WindowsDefender
            }
            else {
                Show-MainMenu
            }
        }
        else {
            Show-MainMenu
        }
    }
    else {
        Show-Header
        Write-Host "Windows Defender is already enabled. No action is needed." -ForegroundColor Green
        Write-Host "Press any key to go back to the main menu."
        Read-Host
        Show-MainMenu
    }
}


# Function to Enable Windows Defender
function Enable-WindowsDefender {
        $MultilineComment = @"
%%Enable_Windows_Defender.reg%%
"@
    Set-Registry "$MultilineComment"

    Write-Host "Windows Defender has been enabled." -ForegroundColor Green
    Write-Host "Press any key to return to the main menu."
    Read-Host
}

# Check if User Account Control is Enabled or Disabled
function Get-UACStatus {
    Clear-Host
    $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    
    # Get the EnableLUA and ConsentPromptBehaviorAdmin values
    $uacStatus = (Get-ItemProperty -Path $uacKey -Name EnableLUA).EnableLUA
    $promptBehavior = (Get-ItemProperty -Path $uacKey -Name ConsentPromptBehaviorAdmin).ConsentPromptBehaviorAdmin

    # Determine if UAC is disabled based on both keys
    if ($uacStatus -eq 0 -or $promptBehavior -eq 0) {
        Show-Header
        Write-Host "User Account Control (UAC) is currently disabled." -ForegroundColor Red
        Write-Host "1. Enable UAC"
    }
    else {
        Show-Header
        Write-Host "User Account Control (UAC) is currently enabled." -ForegroundColor Green
        Write-Host "1. Disable UAC"
    }
    Write-Host "0. Main Menu"
    $choice = Read-Host "Select an option"
    switch ($choice) {
        1 {
            $confirm = Read-Host "Are you sure you want to change UAC status? (y/n)"
            if ($confirm -eq 'y') {
                if ($uacStatus -eq 0) {
                    # Enable UAC and set the default prompt behavior
                    cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f 2>&1 | Out-Null
                    cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f 2>&1 | Out-Null
                    Write-Host "UAC has been enabled successfully." -ForegroundColor Green
                }
                else {
                    # Disable UAC and default prompt behavior
                    cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f 2>&1 | Out-Null
                    cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f 2>&1 | Out-Null
                    Write-Host "UAC has been disabled successfully." -ForegroundColor Green
                }
                Write-Host "Press any key to continue."
                Read-Host
                Get-UACStatus
            }
            else {
                Get-UACStatus
            }
        }
        0 { Return }
        default { Write-Host "Invalid choice. Try again."; Get-UACStatus }
    }
}


# Function to Apply the Recommended Privacy Settings
function Set-RecommendedPrivacySettings {
    
    if (-not $isSpecializePhase) {
        Show-Header
        Write-Host "Applying Recommended Privacy Settings . . ."
    }
        $MultilineComment = @"
%%Recommended_Privacy_Settings.reg%%
"@
    Set-Registry "$MultilineComment"

    if (-not $isSpecializePhase) {
        Show-Header
        Write-Host "Recommended Privacy Settings Applied." -ForegroundColor Green
        Wait-IfNotSpecialize
    }
}


# Function to Apply the Default Privacy Settings
function Set-DefaultPrivacySettings {
    
    Show-Header
    Write-Host "Applying Default Privacy Settings . . ."

        $MultilineComment = @"
%%Default_Privacy_Settings.reg%%
"@
    Set-Registry "$MultilineComment"

    Show-Header
    Write-Host "Default Privacy Settings Applied." -ForegroundColor Green
    Wait-IfNotSpecialize
}

# End of Privacy and Security Functions

# Start of Windows Update Functions
function Set-RecommendedUpdateSettings {

    if (-not $isSpecializePhase) {
        Show-Header
        Write-Host "Applying Recommended Windows Update Settings . . ."
    }

        $MultilineComment = @"
%%Recommended_Windows_Update_Settings.reg%%
"@
    Set-Registry "$MultilineComment"

    if (-not $isSpecializePhase) {
        Show-Header
        Write-Host "Recommended Windows Update Settings Applied." -ForegroundColor Green
        Wait-IfNotSpecialize
    }
}

function Set-DefaultUpdateSettings {

    Show-Header
    Write-Host "Applying Default Windows Update Settings . . ."

        $MultilineComment = @"
%%Default_Windows_Update_Settings.reg%%
"@
    Set-Registry "$MultilineComment"


    Show-Header
    Write-Host "Default Windows Update Settings Applied." -ForegroundColor Green
    Wait-IfNotSpecialize
}
# End of Windows Update Functions

# Start of Registry Optimizations
function Set-RecommendedHKLMRegistry {

    $MultilineComment = @"
%%Optimize_LocalMachine_Registry.reg%%
"@
    Set-Registry "$MultilineComment"

    Show-Header
    Write-Host "Recommended Local Machine Registry Settings Applied." -ForegroundColor Green
    Wait-IfNotSpecialize
}

function Set-DefaultHKLMRegistry {
    $MultilineComment = @"
%%Restore_LocalMachine_Registry.reg%%
"@
    Set-Registry "$MultilineComment"

    Show-Header
    Write-Host "Default Local Machine Registry Settings Applied." -ForegroundColor Green
    Wait-IfNotSpecialize
}


function Set-RecommendedHKCURegistry {
    Clear-Host
    Write-Host "Optimizing User Registry . . ."

    # Set Wallpaper (Helper Function for Recommended User Settings)
    $defaultWallpaperPath = "C:\Windows\Web\4K\Wallpaper\Windows\img0_3840x2160.jpg"
    $darkModeWallpaperPath = "C:\Windows\Web\4K\Wallpaper\Windows\img19_1920x1200.jpg"

    function Set-Wallpaper ($wallpaperPath) {
        reg.exe add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$wallpaperPath" /f | Out-Null
        # Notify the system of the change
        rundll32.exe user32.dll, UpdatePerUserSystemParameters
    }

    # Check Windows version
    $windowsVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild

    # Apply appropriate wallpaper based on Windows version or existence of dark mode wallpaper
    if ($windowsVersion -ge 22000) {
        # Assuming Windows 11 starts at build 22000
        if (Test-Path $darkModeWallpaperPath) {
            Set-Wallpaper -wallpaperPath $darkModeWallpaperPath
        }
    }
    else {
        # Apply default wallpaper for Windows 10
        Set-Wallpaper -wallpaperPath $defaultWallpaperPath
    }

    $MultilineComment = @"
%%Optimize_User_Registry.reg%%
"@
    Set-Registry "$MultilineComment"

    Show-Header
    Write-Host "Recommended User Registry Settings Applied." -ForegroundColor Green
    Wait-IfNotSpecialize
}

function Set-DefaultHKCURegistry {
    Clear-Host
    Write-Host "Restoring User Default Registry Settings . . ."

    $MultilineComment = @"
%%Restore_User_Registry.reg%%
"@
    Set-Registry "$MultilineComment"

    Show-Header
    Write-Host "Default User Registry Settings Applied." -ForegroundColor Green
    Wait-IfNotSpecialize
}
# End of Registry Optimizations

# Start of Tasks and Services Functions
function Set-ServiceStartup {
    # List of services to set to Disabled
    $disabledServices = @(
    'AJRouter', 'AppVClient', 'AssignedAccessManagerSvc', 
    'DiagTrack', 'DialogBlockingService', 'NetTcpPortSharing',
    'RemoteAccess', 'RemoteRegistry', 'shpamsvc', 
    'ssh-agent', 'tzautoupdate', 'uhssvc',
    'UevAgentService'
	)

    # List of services to set to Manual
    $manualServices = @(
    'ALG', 'AppIDSvc', 'AppMgmt', 'AppReadiness', 'AppXSvc', 'Appinfo',
    'AxInstSV', 'BDESVC', 'BITS', 'BTAGService', 'BcastDVRUserService_*',
    'Browser', 'CDPSvc', 'CDPUserSvc_*', 'COMSysApp', 'CaptureService_*',
    'CertPropSvc', 'ClipSVC', 'ConsentUxUserSvc_*', 'CscService', 'DcpSvc',
    'DevQueryBroker', 'DeviceAssociationBrokerSvc_*', 'DeviceAssociationService', 
    'DeviceInstall', 'DevicePickerUserSvc_*', 'DevicesFlowUserSvc_*', 
    'DisplayEnhancementService', 'DmEnrollmentSvc', 'DoSvc', 'DsSvc', 'DsmSvc',
    'EFS', 'EapHost', 'EntAppSvc', 'FDResPub', 'Fax', 'FrameServer',
    'FrameServerMonitor', 'GraphicsPerfSvc', 'HomeGroupListener', 
    'HomeGroupProvider', 'HvHost', 'IEEtwCollectorService', 'IKEEXT',
    'InstallService', 'InventorySvc', 'IpxlatCfgSvc', 'KtmRm', 'LicenseManager',
    'LxpSvc', 'MSDTC', 'MSiSCSI', 'MapsBroker', 'McpManagementService', 
    'MessagingService_*', 'MicrosoftEdgeElevationService', 
    'MixedRealityOpenXRSvc', 'MsKeyboardFilter', 'NPSMSvc_*', 'NaturalAuthentication',
    'NcaSvc', 'NcbService', 'NcdAutoSetup', 'Netman', 'NgcCtnrSvc', 'NgcSvc',
    'NlaSvc', 'P9RdrService_*', 'PNRPAutoReg', 'PNRPsvc', 'PcaSvc', 'PeerDistSvc',
    'PenService_*', 'PerfHost', 'PhoneSvc', 'PimIndexMaintenanceSvc_*', 'PlugPlay',
    'PolicyAgent', 'PrintNotify', 'PrintWorkflowUserSvc_*', 'PushToInstall', 'QWAVE',
    'RasAuto', 'RasMan', 'RetailDemo', 'RmSvc', 'RpcLocator', 'SCPolicySvc',
    'SCardSvr', 'SDRSVC', 'SEMgrSvc', 'SecurityHealthService', 
    'SensorDataService', 'SensorService', 'SensrSvc', 'SessionEnv', 
    'SharedAccess', 'SharedRealitySvc', 'SmsRouter', 'SstpSvc', 
    'StateRepository', 'StiSvc', 'StorSvc', 'TabletInputService', 'TapiSrv',
    'TextInputManagementService', 'TieringEngineService', 'TimeBroker',
    'TimeBrokerSvc', 'TokenBroker', 'TroubleshootingSvc', 'TrustedInstaller',
    'UI0Detect', 'UdkUserSvc_*', 'UmRdpService', 'UnistoreSvc_*', 
    'UserDataSvc_*', 'UsoSvc', 'VSS', 'VacSvc', 'W32Time', 'WEPHOSTSVC',
    'WFDSConMgrSvc', 'WMPNetworkSvc', 'WManSvc', 'WPDBusEnum', 'WSService',
    'WSearch', 'WaaSMedicSvc', 'WalletService', 'WarpJITSvc', 'WbioSrvc',
    'WcsPlugInService', 'WdiServiceHost', 'WdiSystemHost', 'WebClient', 'Wecsvc',
    'WerSvc', 'WiaRpc', 'WinHttpAutoProxySvc', 'WinRM', 'WpcMonSvc', 
    'WpnService', 'WwanSvc', 'XblAuthManager', 'XblGameSave', 'XboxGipSvc', 
    'XboxNetApiSvc', 'autotimesvc', 'bthserv', 'camsvc', 'cbdhsvc_*',
    'cloudidsvc', 'dcsvc', 'defragsvc', 'diagnosticshub.standardcollector.service',
    'diagsvc', 'dmwappushservice', 'dot3svc', 'edgeupdate', 'edgeupdatem', 
    'embeddedmode', 'fdPHost', 'fhsvc', 'hidserv', 'icssvc', 'lfsvc', 
    'lltdsvc', 'lmhosts', 'msiserver', 'netprofm', 'p2pimsvc', 'p2psvc', 
    'perceptionsimulation', 'pla', 'seclogon', 'smphost', 'spectrum', 
    'sppsvc', 'svsvc', 'swprv', 'upnphost', 'vds', 'vm3dservice', 
    'vmicguestinterface', 'vmicheartbeat', 'vmickvpexchange', 'vmicrdv', 
    'vmicshutdown', 'vmictimesync', 'vmicvmsession', 'vmicvss', 'wbengine', 
    'wcncsvc', 'webthreatdefsvc', 'wercplsupport', 'wisvc', 'wlidsvc', 
    'wlpasvc', 'wmiApSrv', 'workfolderssvc', 'wuauserv', 'wudfsvc'
    )

    # Set the services in the disabledServices list to Disabled
    foreach ($service in $disabledServices) {
        try {
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Show-Header
            Write-Host "Failed to set $service to Disabled: $_" -ForegroundColor Yellow
            Wait-IfNotSpecialize
        }
    }

    # Set the services in the manualServices list to Manual
    foreach ($service in $manualServices) {
        try {
            Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Show-Header
            Write-Host "Failed to set $service to Manual: $_" -ForegroundColor Yellow
            Wait-IfNotSpecialize
        }
    }

    Show-Header
    Write-Host "Service startup types updated successfully." -ForegroundColor Green
    Wait-IfNotSpecialize
}

function Set-DefaultServices {
    # Get all services that are not currently set to Automatic and revert them
    $allServices = Get-Service | Where-Object { $_.StartType -ne 'Automatic' }

    $successCount = 0
    foreach ($service in $allServices) {
        try {
            Show-Header
            Write-Host "Setting services to Automatic where permissions are allowed. Please wait . . ."
            # Set the service startup type to Automatic using Set-Service
            Set-Service -Name $service.Name -StartupType Automatic 2>&1 | Out-Null

            # Forcibly set the startup type to Automatic using WMI as a fallback
            $wmiService = Get-WmiObject -Class Win32_Service -Filter "Name='$($service.Name)'" 2>&1 | Out-Null
            if ($wmiService) {
                $result = $wmiService.ChangeStartMode("Automatic") 2>&1 | Out-Null
                if ($result.ReturnValue -eq 0) {
                    $successCount++
                }
            }
        }
        catch {
            # Silently continue if a service fails
            continue
        }
    }
    Show-Header
    Write-Host "Successfully set services to Automatic where permissions allowed." -ForegroundColor Green
    Wait-IfNotSpecialize
}

function Disable-ScheduledTasks {
    # Define the list of scheduled tasks to disable
    $scheduledTasks = @(
        "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "Microsoft\Windows\Autochk\Proxy",
        "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "Microsoft\Windows\Feedback\Siuf\DmClient",
        "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
        "Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "Microsoft\Windows\Application Experience\MareBackup",
        "Microsoft\Windows\Application Experience\StartupAppTask",
        "Microsoft\Windows\Application Experience\PcaPatchDbTask",
        "Microsoft\Windows\Maps\MapsUpdateTask"
    )

    $successCount = 0
    foreach ($task in $scheduledTasks) {
        try {
            # Disable the task without wildcards
            schtasks /Change /TN $task /Disable 2>&1 | Out-Null
            $successCount++
        }
        catch {
            # Silently continue if a task fails
            continue
        }
    }
    
    Show-Header
    Write-Host "Successfully disabled unneeded scheduled tasks." -ForegroundColor Green
    Wait-IfNotSpecialize
}

function Enable-ScheduledTasks {
    # Define the list of scheduled tasks to enable (same as those to disable)
    $scheduledTasks = @(
        "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "Microsoft\Windows\Autochk\Proxy",
        "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "Microsoft\Windows\Feedback\Siuf\DmClient",
        "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
        "Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "Microsoft\Windows\Application Experience\MareBackup",
        "Microsoft\Windows\Application Experience\StartupAppTask",
        "Microsoft\Windows\Application Experience\PcaPatchDbTask",
        "Microsoft\Windows\Maps\MapsUpdateTask"
    )

    $successCount = 0
    foreach ($task in $scheduledTasks) {
        try {
            # Disable the task without wildcards
            schtasks /Change /TN $task /Disable 2>&1 | Out-Null
            $successCount++
        }
        catch {
            # Silently continue if a task fails
            continue
        }
    }
    
    Show-Header
    Write-Host "Successfully Enabled Default scheduled tasks." -ForegroundColor Green
    Wait-IfNotSpecialize
}
# End of Tasks and Services Functions

# Start of Power Settings Functions
function Set-RecommendedPowerSettings {
    Clear-Host
    # Import and set Ultimate power plan
    cmd /c "powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >nul 2>&1 & powercfg /SETACTIVE 99999999-9999-9999-9999-999999999999 >nul 2>&1"

    # Get all power plans and delete them
    powercfg /L | ForEach-Object {
        if ($_ -match "^\s*Power Scheme GUID: (\S+)") {
            $guid = $matches[1]
            if ($guid -ne "99999999-9999-9999-9999-999999999999") {
                cmd /c "powercfg /delete $guid" | Out-Null
            }
        }
    }

    # Registry modifications
    $regChanges = @(
        'HKLM\SYSTEM\CurrentControlSet\Control\Power /v HibernateEnabled /t REG_DWORD /d 0', # Disables hibernate
        'HKLM\SYSTEM\CurrentControlSet\Control\Power /v HibernateEnabledDefault /t REG_DWORD /d 0', # Disables default hibernate settings
        'HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings /v ShowLockOption /t REG_DWORD /d 0', # Hides the Lock option from the Power menu
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings /v ShowSleepOption /t REG_DWORD /d 0', # Hides the Sleep option from the Power menu
        'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power /v HiberbootEnabled /t REG_DWORD /d 0', # Disables Fast Startup (Hiberboot)
        'HKLM\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583 /v ValueMax /t REG_DWORD /d 0', # Unparks CPU cores by setting the maximum processor state
        'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling /v PowerThrottlingOff /t REG_DWORD /d 1', # Disables power throttling
        'HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683 /v Attributes /t REG_DWORD /d 2', # Unhides "Hub Selective Suspend Timeout"
        'HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009 /v Attributes /t REG_DWORD /d 2' # Unhides "USB 3 Link Power Management"
    )


    foreach ($reg in $regChanges) {
        cmd /c "reg add `$reg` /f >nul 2>&1"
    }

    # Modify Power Plan settings
    $settings = @(
        @{
            SubgroupGUID = "0012ee47-9041-4b5d-9b77-535fba8b1442" # Hard Disk
            SettingGUIDs = @("6738e2c4-e8a5-4a42-b16a-e040e769756e") # Turn off hard disk after
        },
        @{
            SubgroupGUID = "0d7dbae2-4294-402a-ba8e-26777e8488cd" # Desktop Background Settings
            SettingGUIDs = @("309dce9b-bef4-4119-9921-a851fb12f0f4") # Slide show
        },
        @{
            SubgroupGUID = "19cbb8fa-5279-450e-9fac-8a3d5fedd0c1" # Wireless Adapter Settings
            SettingGUIDs = @("12bbebe6-58d6-4636-95bb-3217ef867c1a") # Power saving mode
        },
        @{
            SubgroupGUID = "238c9fa8-0aad-41ed-83f4-97be242c8f20" # Sleep
            SettingGUIDs = @(
                "29f6c1db-86da-48c5-9fdb-f2b67b1f44da", # Sleep after
                "94ac6d29-73ce-41a6-809f-6363ba21b47e", # Allow hybrid sleep
                "9d7815a6-7ee4-497e-8888-515a05f02364", # Hibernate after
                "bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d"  # Allow wake timers
            )
        },
        @{
            SubgroupGUID = "2a737441-1930-4402-8d77-b2bebba308a3" # USB Settings
            SettingGUIDs = @(
                "0853a681-27c8-4100-a2fd-82013e970683", # USB selective suspend setting
                "48e6b7a6-50f5-4782-a5d4-53bb8f07e226", # USB 3 Link Power Management
                "d4e98f31-5ffe-4ce1-be31-1b38b384c009"  # USB Hub Selective Suspend Timeout
            )
        },
        @{
            SubgroupGUID = "501a4d13-42af-4429-9fd1-a8218c268e20" # PCI Express
            SettingGUIDs = @("ee12f906-d277-404b-b6da-e5fa1a576df5") # Link State Power Management
        },
        @{
            SubgroupGUID = "7516b95f-f776-4464-8c53-06167f40cc99" # Display settings
            SettingGUIDs = @("3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e") # Turn off Display After setting
        }
    )


    foreach ($group in $settings) {
        $subgroup = $group.SubgroupGUID
        foreach ($setting in $group.SettingGUIDs) {
            powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 $subgroup $setting 0x00000000
            powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 $subgroup $setting 0x00000000
        }
    }

    if (-not $isSpecializePhase) {
        Show-Header
        Write-Host "Recommended Power Settings Applied." -ForegroundColor Green
        Wait-IfNotSpecialize
        return
    }
}

function Set-DefaultPowerSettings {
    Clear-Host
    # Restore default power plans and enable hibernate
    powercfg -restoredefaultschemes
    cmd /c "powercfg /hibernate on >nul 2>&1"
    cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Power`" /v `"HibernateEnabledDefault`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

    # Registry modifications
    $regChanges = @(
        'HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings /v ShowLockOption /t REG_DWORD /d 1',
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings /v ShowSleepOption /t REG_DWORD /d 1',
        'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power /v HiberbootEnabled /t REG_DWORD /d 1',
        'HKLM\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583 /v ValueMax /t REG_DWORD /d 100',
        'HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683 /v Attributes /t REG_DWORD /d 1',
        'HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009 /v Attributes /t REG_DWORD /d 1'
    )

    foreach ($reg in $regChanges) {
        cmd /c "reg add `$reg` /f >nul 2>&1"
    }

    Show-Header
    Write-Host "Default Power Settings Applied." -ForegroundColor Green
    Wait-IfNotSpecialize
    return
}

function Set-Registry {
    param (
        [string]$RegistryEdits
    )
    Set-Content -Path "$env:TEMP\uwscript.reg" -Value $RegistryEdits -Force
    $path = "$env:TEMP\uwscript.reg"
    (Get-Content $path) -replace "\?", "$" | Out-File $path    
    Start-Process -FilePath "regedit.exe" -ArgumentList "/S `"$env:TEMP\uwscript.reg`"" -NoNewWindow -Wait
}


# End of Power Settings Functions

# END OF COMMAND & OPERATION FUNCTIONS

# Check if this is running in the specialize phase to Apply Settings automatically during Windows Installation
if (Test-Path -Path $markerFilePath) {
    # Bloatware Apps
    Get-AppxProvisionedPackage -Online |
    Where-Object { $appxPackages -contains $_.DisplayName } |
    Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction SilentlyContinue
    # Legacy Windows Features & Apps
    Get-WindowsCapability -Online |
    Where-Object { $capabilities -contains ($_.Name -split '~')[0] } |
    Remove-WindowsCapability -Online -ErrorAction SilentlyContinue
    # Additional Software & Apps
    Set-AppsRegistry
    Remove-OneDrive
    Disable-Recall
    # Privacy & Security
    Set-RecommendedPrivacySettings
    # Windows Updates
    Set-RecommendedUpdateSettings
    # Optimize Registry
    Set-RecommendedHKLMRegistry
    # Tasks and Services
    Disable-ScheduledTasks
    Set-ServiceStartup
    # Power Settings
    Set-RecommendedPowerSettings
    exit
}

# Main loop to keep showing the main menu
while ($script:loop) {
    Show-MainMenu
}