# Today's inflight entertainment brought to you by
$sandboxieStart = 'C:\Users\Quadstronaut\scoop\apps\sandboxie-plus-np\current\Start.exe'
$edminlauncher = 'G:\SteamLibrary\steamapps\common\Elite Dangerous\MinEdLauncher.exe'

# Launch!
$sbsTrue = Test-Path $sandboxieStart
$edmlTrue = Test-Path $edminlauncher
if ($sbsTrue -and $edmlTrue){
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRDuvrazh `"$edminlauncher`" /frontier Account1 /edo /autorun /autoquit /skipInstallPrompt"
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRBistronaut `"$edminlauncher`" /frontier Account2 /edo /autorun /autoquit /skipInstallPrompt"
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRTristronaut `"$edminlauncher`" /frontier Account3 /edo /autorun /autoquit /skipInstallPrompt"
    Start-Process -FilePath $sandboxieStart -ArgumentList "/box:CMDRQuadstronaut `"$edminlauncher`" /frontier Account4 /edo /autorun /autoquit /skipInstallPrompt"
}