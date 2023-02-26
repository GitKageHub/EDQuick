[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Autoconfig,
    [Parameter(Mandatory = $false)]
    [switch]$Config,
    [Parameter(Mandatory = $false)]
    [switch]$EliteDangerous,
    [Parameter(Mandatory = $false)]
    [switch]$EDDiscovery,
    [Parameter(Mandatory = $false)]
    [switch]$EDEngineer,
    [Parameter(Mandatory = $false)]
    [switch]$EDHM_UI,
    [Parameter(Mandatory = $false)]
    [switch]$EDMarketConnector,
    [Parameter(Mandatory = $false)]
    [switch]$EliteObservatory,
    [Parameter(Mandatory = $false)]
    [switch]$EliteOdysseyMaterialsHelper,
    [Parameter(Mandatory = $false)]
    [switch]$EliteTrack,
    [Parameter(Mandatory = $false)]
    [switch]$Help,
    [Parameter(Mandatory = $false)]
    [switch]$Install,
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall,
    [Parameter(Mandatory = $false)]
    [switch]$VoiceAttack = $false
)

if ($Config) {
    $ConfigModeTriggered = $true
} else {
    $ConfigModeTriggered = $false
}

if ($help) {
    Start-Process 'https://github.com/GitKageHub/EDQuick' -ErrorAction SilentlyContinue
    Exit 0
}

if ($Install -or $Uninstall) {
    $InstallerModeTriggered = $true
} else {
    $InstallerModeTriggered = $false
}

if ($ConfigModeTriggered -eq $true -and $InstallerModeTriggered -eq $true) {
    Write-Host 'You cannot use both config and install/uninstall switches at the same time.' -ForegroundColor Red
    Exit 1
}

### Functions ###

function DefaultConfig () {
    return @{
        EDDiscovery                 = @{
            Path        = "$env:ProgramFiles\EDDiscovery\EDDiscovery.exe"
            IsInstalled = $false
            Source      = 'https://github.com/EDDiscovery/EDDiscovery/releases/latest'
            Type        = 'exe' # /SILENT
        }
        EDEngineer                  = @{
            Path        = "$env:LocalAppData\EDEngineer\EDEngineer.exe"
            IsInstalled = $false
            Source      = 'https://raw.githubusercontent.com/msarilar/EDEngineer/master/EDEngineer/releases/setup.exe'
            Type        = 'exe' # /VERYSILENT
        }
        EDHM_UI                     = @{
            Path        = "$env:LocalAppData\Local\EDHM_UI\EDHM_UI_mk2.exe"
            IsInstalled = $false
            Source      = 'https://github.com/BlueMystical/EDHM_UI/releases/latest'
            Type        = 'msi' # /quiet
        }
        EDMarketConnector           = @{
            Path        = "$env:ProgramFiles(x86)\EDMarketConnector\EDMarketConnector.exe"
            IsInstalled = $false
            Source      = 'https://github.com/EDCD/EDMarketConnector/releases/latest'
            Type        = 'msi' # /quiet
        }
        EliteDangerous              = @{
            Path        = 'steam://rungameid/359320'
            IsInstalled = $false
            Source      = $null
            Type        = $null
        }
        EliteObservatory            = @{
            Path        = "$env:ProgramFiles\Elite Observatory\ObservatoryCore.exe"
            IsInstalled = $false
            Source      = 'https://github.com/Xjph/ObservatoryCore/releases/latest'
            Type        = 'exe' # /VERYSILENT
        }
        EliteOdysseyMaterialsHelper = @{
            Path        = "$env:LocalAppData\Elite Dangerous Odyssey Materials Helper Launcher\Elite Dangerous Odyssey Materials Helper Launcher.exe"
            IsInstalled = $false
            Source      = 'https://github.com/jixxed/ed-odyssey-materials-helper/releases/latest'
            Type        = 'msi' # /quiet
        }
        EliteTrack                  = @{
            Path        = "$env:LocalAppData\Programs\EliteTrack\EliteTrack.exe"
            IsInstalled = $false
            Source      = 'https://twitch.extensions.barrycarlyon.co.uk/elitetrack/app/current/'
            Type        = 'exe' # no silent option
        }
        VoiceAttack                 = @{
            Path        = "$env:ProgramFiles\VoiceAttack\VoiceAttack.exe"
            IsInstalled = $false
            Source      = 'https://voiceattack.com/Downloads.aspx' # user must download manually
            Type        = 'zip'
        }
    }
}

function IsAdmin() {
    return (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
}

function StartSecondScreen ($appPath) {
    $process = Start-Process $appPath -PassThru
    # Get the handle of the main window of the process
    $windowHandle = $process.MainWindowHandle
    # Get the handle of the secondary monitor
    $secondaryMonitor = (Get-WmiObject -Namespace root\wmi -Class WmiMonitorBasicDisplayParams | Where-Object { $_.IsActive -eq $true }).InstanceName
    # Move the window to the secondary monitor
    $winAPI = Add-Type -Name WinAPI -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
'@
    $winAPI::SetWindowPos($windowHandle, 0, $secondaryMonitor.ScreenWidth, 0, 0, 0, 0x0001)
}

function TestExistSteam {
    $SteamRegistryKey = 'HKLM:\Software\Valve\Steam'
    $SteamExecutablePath = 'C:\Program Files (x86)\Steam\steam.exe'
    if (Test-Path $SteamRegistryKey -PathType Any -ErrorAction SilentlyContinue -ErrorVariable _) {
        return $true
    } elseif (Test-Path $SteamExecutablePath -PathType Leaf) {
        return $true
    } else {
        return $false
    }
}

### Logic ###

# Check if running as administrator, fix shortcut and relaunch if not
if (-not (IsAdmin)) {
    $shell = New-Object -ComObject WScript.Shell
    $currentFile = Split-Path -Leaf $MyInvocation.MyCommand.Path
    foreach ($file in Get-ChildItem -Path $PWD -Filter *.lnk) {
        if (Split-Path -Leaf $file.Name -eq $currentFile) {
            $currentLnk = $shell.CreateShortcut($file.FullName)
            $currentLnk.Arguments += ' -Verb runas'
            $currentLnk.Save()
            $shell.Run($currentLnk.FullName)
            Stop-Process -Id $PID
        }
    }
}
$EDQConfig = $null
$EDQConfigPath = "$env:LocalAppData\EDQuick\EDQuick.psd1"
$EDQConfigDirectory = Split-Path $EDQConfigPath -Parent
$ConfigExists = Test-Path -Path $EDQConfigPath -PathType Leaf -ErrorAction SilentlyContinue

# Check if a DataFile exists
if ($ConfigExists) {
    $EDQConfig = Import-Clixml -Path $EDQConfigPath
} else {
    New-Item -ItemType Directory -Force -Path $EDQConfigDirectory -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path $EDQConfigPath -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
    $EDQConfig = DefaultConfig
    $EDQConfig | Export-Clixml -Path $EDQConfigPath
}

# Reconfigure launchers
if ($ConfigModeTriggered -eq $true) {
    # Detect which apps are installed
    foreach ($app in $EDQConfig.GetEnumerator()) {
        $path = $app.Value['Path']
        # Steam is special, sorry if you installed Elite from elsewhere (open an issue on GitHub if you want to add support for that)
        if ($app.Key -eq 'EliteDangerous') {
            if (TestExistSteam) {
                $EDQConfig[$app.Key]['IsInstalled'] = $true
            } else {
                $EDQConfig[$app.Key]['IsInstalled'] = $false
            }
        } elseif (Test-Path -Path $path) {
            $EDQConfig[$app.Key]['IsInstalled'] = $true
        } else {
            $EDQConfig[$app.Key]['IsInstalled'] = $false
        }
    }

    # Ask user which apps to run
    foreach ($app in $EDQConfig.GetEnumerator()) {
        if ($app.Value['IsInstalled']) {
            $isEnabled = Read-Host "Do you want to enable $($app.Key)? (Y/N)"
            $isEnabled = $true
            $EDQConfig[$item.Key]['IsInstalled'] = $isEnabled
        }
    }
    $EDQConfig | Export-Clixml -Path $EDQConfigPath
} 
$EDQConfig = Import-Clixml -Path $EDQConfigPath

# Installer/update software
if ($InstallerModeTriggered -eq $true) {
    # Loop to render a numbered table
    do {
        # Filter out apps with $null Source like Steam (not handling that yet)
        $configApps = $EDQConfig | Where-Object { $_.Source -ne $null }

        # Render the table with Name and IsInstalled columns
        $configApps | Select-Object @{Name = 'Number'; Expression = { $i } }, Name, IsInstalled | Format-Table -AutoSize

        # Prompt the user to select an app
        $selected = Read-Host 'Enter the number of the app to install/uninstall or press Enter/Esc to exit'

        # Get the selected app by number
        $selectedApp = $configApps[$selected - 1]

        # Set the status of the selected app to "In Progress"
        $selectedApp.IsInstalled = 'In Progress'
        Write-Host "Selected app: $($selectedApp.Name). $($selectedApp.Type) installation status: $($selectedApp.IsInstalled)"

        # Define the installation job name based on the app value
        $jobName = "Install-$($selectedApp.Type)"

        # Define the installation file path and parameters based on the app value
        $filePath = "C:\Windows\Temp\$($selectedApp.Type)"
        $parameters = ''
        switch ($selectedApp.Type) {
            'eddiscovery' {
                $parameters = '/SILENT'
            }
            'EDEngineer' {
                $parameters = '/VERYSILENT'
            }
            'EDHM_UI' {
                $parameters = '/quiet'
            }
            'EDMarketConnector' {
                $parameters = '/quiet'
            }
            'EliteDangerous' {
                # Do nothing, skip installation
            }
            'EliteObservatory' {
                $parameters = '/VERYSILENT'
            }
            'EliteOdysseyMaterialsHelper' {
                $parameters = '/quiet'
            }
            'EliteTrack' {
                # Just execute the exe and wait for user to finish
                Start-Process $selectedApp.Source -Wait
            }
            'VoiceAttack' {
                # Just send user to the website in Source with default browser
                Start-Process $selectedApp.Source
            }
        }

        # If the selected app is not EliteDangerous, download and install the file
        if ($selectedApp.Type -ne 'EliteDangerous' -and $selectedApp.Type -ne 'EliteTrack' -and $selectedApp.Type -ne 'VoiceAttack') {
            # Download the installation file from the Source
            Write-Host "Downloading $($selectedApp.Type) installation file from $($selectedApp.Source)..."
            $response = Invoke-WebRequest $selectedApp.Source
            $contentDisposition = $response.Headers['Content-Disposition']
            if ($contentDisposition -match "filename=`"(.*?)`"") {
                $fileName = $matches[1]
                $filePath = "C:\Windows\Temp\$fileName"
            }
            $response.Content | Set-Content $filePath

            # Install the file with the specified parameters in a background job
            Write-Host "Installing $($selectedApp.Type)..."
            Start-Job -Name $jobName -ScriptBlock { Start-Process $args[0] $args[1] -Wait } -ArgumentList $filePath, $parameters | Out-Null

            # Set the status of the selected app to "Installed" once the job completes
            Register-ObjectEvent -InputObject (Get-Job -Name $jobName) -EventName StateChanged -Action {
                if ($EventArgs.JobStateInfo.State -eq 'Completed') {
                    $selectedApp.IsInstalled = 'Installed'
                    Write-Host "$($selectedApp.Type) installation complete."
                }
            } | Out-Null
        }

        # Set the status of the selected app to "Not Installed" or "Already Uninstalled" if the file doesn't exist
        else {
            $fileExists = Test-Path $filePath
            $selectedApp.IsInstalled = 'Not Installed'
            if ($uninstall) {
                $selectedApp.IsInstalled = 'Already Uninstalled'
            }
            if ($fileExists) {
                # Set the status of the selected app to "Installed" or "Uninstalled" depending on the value of the `$uninstall` variable
                $selectedApp.IsInstalled = 'Installed'
                if ($uninstall) {
                    $selectedApp.IsInstalled = 'Uninstalled'
                }
                Write-Host "$($selectedApp.Name) installation status: $($selectedApp.IsInstalled)"
            } else {
                Write-Host "$($selectedApp.Name) installation status: $($selectedApp.IsInstalled)"
            }
        }

        # Exit the loop if user presses Enter or Esc
        if ($selected -eq '' -or $selected -eq [char]27) {
            break
        }
    } while ($true)

    # If the selected app is EliteTrack, VoiceAttack, or is being uninstalled, set the status to "Installed" or "Uninstalled" based on the file existence check
    if ($selectedApp.Type -eq 'EliteTrack' -or $selectedApp.Type -eq 'VoiceAttack' -or $uninstall) {
        $filePath = "C:\Windows\Temp\$($selectedApp.Type)"
        $fileExists = Test-Path $filePath
        if ($fileExists) {
            $selectedApp.IsInstalled = $true
            if ($uninstall) {
                $selectedApp.IsInstalled = $false
            }
            Write-Host "$($selectedApp.Name) installation status: $($selectedApp.IsInstalled)"
        } else {
            $selectedApp.IsInstalled = $false
            if ($uninstall) {
                $selectedApp.IsInstalled = 'Already Uninstalled'
            }
            Write-Host "$($selectedApp.Name) installation status: $($selectedApp.IsInstalled)"
        }
    }
    exit 0
}

# Ignition System
if (($ConfigModeTriggered -eq $false) -and ($InstallerModeTriggered -eq $false)) {
    # Community Data
    if ($EDMarketConnector) { StartSecondScreen($EDQConfig.EDMarketConnector.Path) }
    if ($EDDiscovery) { StartSecondScreen($Path_EDDiscovery) }
    if ($EliteOdysseyMaterialsHelper) { StartSecondScreen($Path_EliteOdysseyMaterialsHelper) }
    
    # Local Software
    if ($EDEngineer) { StartSecondScreen($Path_EDEngineer) }
    if ($EliteDangerous) { Start-Process -FilePath $Path_EliteDangerous }
    if ($EDHM_UI) { StartSecondScreen($Path_EDHM_UI) }
    if ($EliteObservatory) { StartSecondScreen($Path_EliteObservatory) }
    if ($VoiceAttack) { StartSecondScreen($Path_VoiceAttack) }

    # Streaming
    if ($EliteTrack) { StartSecondScreen($Path_EliteTrack) }
}
# See you space cowboy...