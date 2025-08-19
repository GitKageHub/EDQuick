### User Config ###
$DestinationPath = 'G:\EliteApps'

# The URL for the Elite Dangerous Exploration Buddy website.
$websiteUrl = "https://www.panostrede.de/EDEB/"

# Use a try/catch block for robust error handling.

$htmlContent = Invoke-WebRequest -Uri $websiteUrl -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

# Find the link to the .msi file.
# We're looking for an anchor tag (<a>) where the href attribute ends with ".msi".
# The links are available in the 'links' property of the Invoke-WebRequest result.
$msiLink = $htmlContent.Links | Where-Object { $_.href -match '\.msi$' }

# Check if the link was found.
if (-not $msiLink) {
    throw "'.msi' not found."
}
    
# If the link is relative, prepend base URL.
$downloadUrl = $msiLink.href
if ($downloadUrl -notmatch "https?://") {
    $uri = New-Object System.Uri($websiteUrl)
    $downloadUrl = New-Object System.Uri($uri, $msiLink.href).AbsoluteUri
}

# Set destination path
if (-not $DestinationPath) {
    # Default to the user's Downloads folder.
    $DestinationPath = Join-Path -Path "$env:USERPROFILE" -ChildPath "Downloads"
    # Ensure the directory exists.
    if (-not (Test-Path $DestinationPath)) {
        New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null
    }
}

# Extract the filename from the URL.
$fileName = [System.IO.Path]::GetFileName($downloadUrl)
$filePath = Join-Path -Path $DestinationPath -ChildPath $fileName
Invoke-WebRequest -Uri $downloadUrl -OutFile $filePath