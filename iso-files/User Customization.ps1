# Check if script is running as Administrator
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Try {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit
    } Catch {
        Write-Host "Failed to run as Administrator. Please rerun with elevated privileges."
        Exit
    }
}

# Disable automatic restart of explorer.exe
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoRestartShell /t REG_DWORD /d 0 /f
# Set desktop background to black
reg.exe add "HKEY_CURRENT_USER\Control Panel\Colors" /v Background /t REG_SZ /d "0 0 0" /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

# Stop explorer.exe
Stop-Process -Name explorer -Force

# Define the XAML UI as a string
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="User Account Customization" Width="700" Height="500" WindowStyle="None" WindowStartupLocation="CenterScreen"
        Background="Transparent" AllowsTransparency="True" Foreground="#ffffff" FontFamily="Futura">
    
    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" ResizeBorderThickness="0" GlassFrameThickness="0"/>
    </WindowChrome.WindowChrome>

    <Window.Resources>
        <!-- Button style when enabled -->
        <Style x:Key="PrimaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#FFDE00"/> <!-- Your primary yellow -->
            <Setter Property="Foreground" Value="Black"/> <!-- Contrast text color -->
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="FontFamily" Value="Futura"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <!-- Hover effect -->
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#FFE533"/> <!-- Lighter yellow on hover -->
                            </Trigger>
                            <!-- Disabled state -->
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#FFEB99"/> <!-- Lighter yellow for disabled -->
                                <Setter Property="Foreground" Value="LightGray"/> <!-- Lighter grey text for disabled -->
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border CornerRadius="15" Background="#202020" Opacity="0.95">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="165*"/>
                <!-- Header Section -->
                <RowDefinition Height="115" />
                <!-- Defender Section -->
                <RowDefinition Height="128*" />
                <!-- UAC Section -->
                <RowDefinition Height="Auto" MinHeight="92.001"/>
                <!-- Restart Button Section -->
            </Grid.RowDefinitions>

            <!-- Header Section -->
            <TextBlock Text="User Account Customization" FontSize="34" HorizontalAlignment="Center" Margin="0,30,0,83" Width="424">
                <TextBlock.Effect>
                    <DropShadowEffect/>
                </TextBlock.Effect>
            </TextBlock>
            
            <StackPanel Orientation="Vertical" Margin="32,97,32,0" VerticalAlignment="Top" Grid.Row="0" Height="58">
                <TextBlock x:Name="StatusMessage" Text="Recommended User settings have been applied successfully ✓" FontSize="20"/>
                <TextBlock Width="634" Text="Visit 'C:\Windows\Setup\Scripts' to Reapply or Revert Settings." FontSize="16" FontStyle="Italic" Height="22" HorizontalAlignment="Left" Margin="0,0,124,-34"/>
            </StackPanel>

            <Rectangle Fill="Gray" Height="2" Width="700" HorizontalAlignment="Center" Margin="0,163,0,0"/>

            <!-- Defender Section in its own StackPanel -->
            <StackPanel Orientation="Vertical" HorizontalAlignment="Center" VerticalAlignment="Top" Height="107" Width="586" Grid.Row="1" Margin="0,10,0,0" Grid.RowSpan="2">
                <TextBlock Text="Checking Windows Defender Status . . ." x:Name="DefenderStatusText" Margin="0,2,0,10" HorizontalAlignment="Center" FontSize="22">
                    <TextBlock.Effect>
                        <DropShadowEffect/>
                    </TextBlock.Effect>
                </TextBlock>
                <TextBlock Width="634" Text="Default=Disabled. If Enabled here or with a script later, it can't be disabled again." FontSize="16" FontStyle="Italic" Height="22" HorizontalAlignment="Left" Margin="0,-8,0,-8"/>
                <Button x:Name="EnableDefenderButton" Content="Enable Defender" Width="150" Height="35" 
                        Style="{StaticResource PrimaryButtonStyle}" HorizontalAlignment="Center" Margin="5,5,5,-65"/>
            </StackPanel>

            <Rectangle Grid.Row="2" Fill="Gray" Height="2" Width="700" HorizontalAlignment="Center" Margin="0,7,0,119"/>

            <!-- UAC Section in its own StackPanel -->
            <StackPanel Orientation="Vertical" HorizontalAlignment="Center" VerticalAlignment="Top" Grid.Row="2" Margin="0,14,0,0" Height="114" Width="586">
                <TextBlock x:Name="UACStatusText" Text="Checking UAC Status . . ." FontSize="22" HorizontalAlignment="Center">
                    <TextBlock.Effect>
                        <DropShadowEffect/>
                    </TextBlock.Effect>
                </TextBlock>
                <TextBlock Width="634" Text="Default=Disabled. Enable UAC here or in Control Panel later if needed." FontSize="16" FontStyle="Italic" Height="22" HorizontalAlignment="Left" Margin="0,-8,0,-40"/>
                <Button x:Name="EnableUACButton" Content="Enable UAC" Width="150" Height="35" 
                        Style="{StaticResource PrimaryButtonStyle}" HorizontalAlignment="Center" Margin="5,5,5,-115" IsEnabled="False"/>
            </StackPanel>

            <Rectangle Grid.Row="3" Fill="Gray" Height="2" Width="700" HorizontalAlignment="Center" Margin="0,10,0,80"/>

            <!-- Restart Button Section -->
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,65,0,0" Grid.Row="3" Height="0" Width="0"/>
            <Button Content="Restart to Apply Changes" x:Name="RestartButton" Margin="225,25,225,25" Grid.Row="3" 
                    Style="{StaticResource PrimaryButtonStyle}">
                <Button.Triggers>
                    <EventTrigger RoutedEvent="ButtonBase.Click">
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetProperty="Opacity" To="0.5" Duration="0:0:0.2"/>
                                <DoubleAnimation Storyboard.TargetProperty="Opacity" To="1.0" BeginTime="0:0:0.2" Duration="0:0:0.2"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </EventTrigger>
                </Button.Triggers>
            </Button>
        </Grid>
    </Border>
</Window>
"@

# Define Unicode characters for checkmark and cross
$checkmark = [char]0x2713  # Unicode for ✓
$cross = [char]0x2717      # Unicode for ✗

# Load XAML
Add-Type -AssemblyName PresentationFramework
[xml]$xamlParsed = $xaml
$xamlWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xamlParsed))

# Applies User Account Settings
Try {

# Uninstall Copilot
Get-AppxPackage -Name 'Microsoft.Copilot' | Remove-AppxPackage
Get-AppxPackage -Name 'Microsoft.Windows.Ai.Copilot.Provider' | Remove-AppxPackage

$MultilineComment = @"
"@
                Set-Content -Path "$env:TEMP\Optimize_User_Registry.reg" -Value $MultilineComment -Force
                
                # Import registry file silently
                Regedit.exe /S "$env:TEMP\Optimize_User_Registry.reg"

# Set Wallpaper
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
if ($windowsVersion -ge 22000) {  # Assuming Windows 11 starts at build 22000
    if (Test-Path $darkModeWallpaperPath) {
        Set-Wallpaper -wallpaperPath $darkModeWallpaperPath
    }
} else {
    # Apply default wallpaper for Windows 10
    Set-Wallpaper -wallpaperPath $defaultWallpaperPath
}

    # Update the XAML TextBlock with the success message
    $xamlWindow.FindName("StatusMessage").Text = "Recommended User settings have been applied successfully $checkmark"
} Catch {
    # Update the XAML TextBlock with the failure message
    $xamlWindow.FindName("StatusMessage").Text = "Failed to apply Recommended User settings $cross"
}

# Check Windows Defender status by inspecting the registry key
$defenderStatus = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -ErrorAction SilentlyContinue

If ($defenderStatus.Start -eq 4) {
    # Windows Defender is disabled, update the Defender TextBlock and make button available
    $xamlWindow.FindName("DefenderStatusText").Text = "Windows Defender is Disabled."
    $xamlWindow.FindName("EnableDefenderButton").IsEnabled = $true  # Enable the button
} Else {
    # Windows Defender is enabled, update the Defender TextBlock and disable the button
    $xamlWindow.FindName("DefenderStatusText").Text = "Windows Defender is Enabled."
    $xamlWindow.FindName("EnableDefenderButton").IsEnabled = $false  # Disable the button
}

# Check UAC status by inspecting the registry key
$uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue

If ($uacStatus.EnableLUA -eq 0) {
    # UAC is disabled, update the UAC TextBlock and make button available
    $xamlWindow.FindName("UACStatusText").Text = "User Account Control is Disabled."
    $xamlWindow.FindName("EnableUACButton").IsEnabled = $true  # Enable the button
} Else {
    # UAC is enabled, update the UAC TextBlock and disable the button
    $xamlWindow.FindName("UACStatusText").Text = "User Account Control is Enabled."
    $xamlWindow.FindName("EnableUACButton").IsEnabled = $false  # Disable the button
}

# Define Event Handlers for Defender and UAC
$xamlWindow.FindName("EnableDefenderButton").Add_Click({
    $result = [System.Windows.MessageBox]::Show("Are you sure you want to enable Windows Defender?", "Confirm Action", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    If ($result -eq 'Yes') {
        Try {
            $MultilineComment = @"
Windows Registry Editor Version 5.00

; Enables Windows Defender to start in Windows Security
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Sense]
"Start"=dword:00000003

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdBoot]
"Start"=dword:00000000

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdFilter]
"Start"=dword:00000000

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdNisDrv]
"Start"=dword:00000003

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WdNisSvc]
"Start"=dword:00000003

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend]
"Start"=dword:00000002
"@
Set-Content -Path "$env:TEMP\Enable_Windows_Defender.reg" -Value $MultilineComment -Force
# edit reg file
$path = "$env:TEMP\Enable_Windows_Defender.reg"
(Get-Content $path) -replace "\?","$" | Out-File $path
# import reg file
Regedit.exe /S "$env:TEMP\Enable_Windows_Defender.reg"
            [System.Windows.MessageBox]::Show("Windows Defender has been enabled. Restart to Apply Changes.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } Catch {
            [System.Windows.MessageBox]::Show("Failed to enable Windows Defender.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
})

$xamlWindow.FindName("EnableUACButton").Add_Click({
    $result = [System.Windows.MessageBox]::Show("Are you sure you want to enable UAC?", "Confirm Action", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    If ($result -eq 'Yes') {
        Try {
            Write-Output "Enable UAC Button Clicked"
            cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 3 /f
            [System.Windows.MessageBox]::Show("User Account Control (UAC) has been successfully enabled.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } Catch {
            [System.Windows.MessageBox]::Show("Failed to enable UAC.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
})

$xamlWindow.FindName("RestartButton").Add_Click({
    $result = [System.Windows.MessageBox]::Show("Are you sure you want to restart your computer?", "Confirm Restart", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    If ($result -eq 'Yes') {
        Try {
            Write-Output "Restart Button Clicked"
            reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoRestartShell /t REG_DWORD /d 1 /f
            Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 1" -NoNewWindow
        } Catch {
            [System.Windows.MessageBox]::Show("Failed to restart the computer.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
})
# Show the Window
$xamlWindow.ShowDialog()