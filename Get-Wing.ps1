# --- FUNCTION TO MOVE AND RESIZE WINDOWS ---

# Function to move and resize a window to specific X/Y coordinates.
# It now returns a boolean to indicate success or failure.
function Set-WindowPosition {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$WindowTitle
    )
    
    # C# code to call the Windows API function SetWindowPos
    Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class User32 {
            [DllImport("user32.dll")]
            public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        }
"@
    
    # Flag values for the SetWindowPos function
    $SWP_NOZORDER = 4
    
    # Find the process by name and window title
    $process = Get-Process -Name "EliteDangerous64" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like "*$WindowTitle*" }
    
    if ($process) {
        $handle = $process.MainWindowHandle
        [User32]::SetWindowPos($handle, [IntPtr]::Zero, $X, $Y, $Width, $Height, $SWP_NOZORDER)
        Write-Host "Moved and resized window for $($WindowTitle) to X=$X, Y=$Y, W=$Width, H=$Height"
        return $true
    }
    else {
        # The window wasn't found, which is a normal state while we wait for it to load.
        # We return false to indicate that it has not been moved yet.
        Write-Warning "Process with title '$($WindowTitle)' not found. Waiting..."
        return $false
    }
}


# --- SCRIPT CONFIGURATION AND LAUNCH ---

# Define the paths for your executables
$sandboxieStart = 'C:\Users\Quadstronaut\scoop\apps\sandboxie-plus-np\current\Start.exe'
$edminlauncher = 'G:\SteamLibrary\steamapps\common\Elite Dangerous\MinEdLauncher.exe'

# Define the accounts to move and their target coordinates/dimensions
# Added a 'Moved' property to each object to track its status.
$boxes = @(
    @{ Name = "[CMDRBistronaut] Elite Dangerous (CLIENT)"; X = -1080; Y = -387; Width = 800; Height = 600; Moved = $false },
    @{ Name = "[CMDRTristronaut] Elite Dangerous (CLIENT)"; X = -1080; Y = 213; Width = 800; Height = 600; Moved = $false },
    @{ Name = "[CMDRQuadstronaut] Elite Dangerous (CLIENT)"; X = -1080; Y = 813; Width = 800; Height = 600; Moved = $false }
)
$edmcs = @(
    @{ Name = "[CMDRDuvrazh] E:D Market Connector"; X = -480; Y = 1213; Width = 800; Height = 600; Moved = $false },
    @{ Name = "[CMDRBistronaut] E:D Market Connector"; X = -480; Y = -387; Width = 800; Height = 600; Moved = $false },
    @{ Name = "[CMDRTristronaut] E:D Market Connector"; X = -480; Y = 213; Width = 800; Height = 600; Moved = $false },
    @{ Name = "[CMDRQuadstronaut] E:D Market Connector"; X = -480; Y = 813; Width = 800; Height = 600; Moved = $false }
)

# Check that the necessary executables exist
$sbsTrue = Test-Path $sandboxieStart
$edmlTrue = Test-Path $edminlauncher

if ($sbsTrue -and $edmlTrue) {
    # Launch all four Elite Dangerous instances simultaneously.
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRDuvrazh `"$edminlauncher`" /frontier Account1 /edo /autorun /autoquit /skipInstallPrompt"
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRBistronaut `"$edminlauncher`" /frontier Account2 /edo /autorun /autoquit /skipInstallPrompt"
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRTristronaut `"$edminlauncher`" /frontier Account3 /edo /autorun /autoquit /skipInstallPrompt"
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRQuadstronaut `"$edminlauncher`" /frontier Account4 0/edo /autorun /autoquit /skipInstallPrompt"
    Start-Sleep -Seconds 30

    # Move Elite Dangerous clients to secondary monitor and tile with pixel perfection
    do {
        # Loop through each box configuration
        foreach ($box in $boxes) {
            # Only try to move windows that haven't been successfully moved yet
            if ($box.Moved -eq $false) {
                # If the function call is successful, update the 'Moved' property
                if (Set-WindowPosition -X $box.X -Y $box.Y -Width $box.Width -Height $box.Height -WindowTitle $box.Name) {
                    $box.Moved = $true
                }
            }
        }
        # Wait a moment before checking again to prevent high CPU usage
        Start-Sleep -Milliseconds 500
        # The loop will exit when the count of windows that haven't been moved is 0
    } until ( ($boxes | Where-Object { $_.Moved -eq $false }).Count -eq 0 )

    # Move E:D Market Connectors to Client(0,800)
    do {
        # Loop through each box configuration
        foreach ($edmc in $edmcs) {
            # Only try to move windows that haven't been successfully moved yet
            if ($edmc.Moved -eq $false) {
                # If the function call is successful, update the 'Moved' property
                if (Set-WindowPosition -X $edmc.X -Y $edmc.Y -Width $edmc.Width -Height $edmc.Height -WindowTitle $edmc.Name) {
                    $edmc.Moved = $true
                }
            }
        }
        # Wait a moment before checking again to prevent high CPU usage
        Start-Sleep -Milliseconds 500
    
        # The loop will exit when the count of windows that haven't been moved is 0
    } until ( ($edmcs | Where-Object { $_.Moved -eq $false }).Count -eq 0 )
}
else {
    Write-Error "Could not find one or more required executables. Check your paths."
}