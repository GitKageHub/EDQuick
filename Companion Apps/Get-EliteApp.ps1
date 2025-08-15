# This script defines a reusable function
# compatible with PowerShell 5.1 on Windows 10
# to download and extract a GitHub release.

function Invoke-GitHubReleaseDownload {
    <#
    .SYNOPSIS
        Downloads and extracts a specified release from a GitHub repository.

    .DESCRIPTION
        This function connects to the GitHub API to find the latest (or pre-release)
        asset matching a filename pattern, downloads the file, and extracts it to
        a specified destination. It explicitly handles JSON parsing for
        compatibility with PowerShell 5.1.

    .PARAMETER Repo
        The GitHub repository in the format "owner/repo".
        Example: "rfvgyhn/min-ed-launcher"

    .PARAMETER FilenamePattern
        A wildcard pattern to match the asset's filename.
        Example: "*win-x64.zip"

    .PARAMETER PathExtract
        The destination path where the archive will be extracted.
        The function will remove this directory and its contents before extraction.

    .PARAMETER InnerDirectory
        A switch parameter. If present, the function assumes the archive contains
        a single top-level directory and moves its contents to the destination path.
        If not present, the archive is extracted directly to the destination path.

    .PARAMETER PreRelease
        A switch parameter. If present, the function will look for the latest
        pre-release asset instead of the latest stable release.

    .EXAMPLE
        Invoke-GitHubReleaseDownload -Repo "rfvgyhn/min-ed-launcher" -FilenamePattern "*win-x64.zip" -PathExtract "G:\EliteApps\min-ed-launcher" -InnerDirectory

    .EXAMPLE
        Invoke-GitHubReleaseDownload -Repo "someuser/someotherrepo" -FilenamePattern "*.zip" -PathExtract "C:\myapps\app"

    .EXAMPLE
        Invoke-GitHubReleaseDownload -Repo "someuser/anothertestrepo" -FilenamePattern "*.7z" -PathExtract "C:\temp\newapp" -PreRelease
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$FilenamePattern,

        [Parameter(Mandatory = $true)]
        [string]$PathExtract,

        [Parameter(Mandatory = $false)]
        [switch]$InnerDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$PreRelease
    )

    try {
        # Define the API endpoint and get the response content
        if ($PreRelease) {
            Write-Host "Searching for latest pre-release..." -ForegroundColor Cyan
            $releasesUri = "https://api.github.com/repos/$Repo/releases"
            # Get the raw JSON content and convert it to an object
            $releaseData = Invoke-WebRequest -Uri $releasesUri | Select-Object -ExpandProperty Content | ConvertFrom-Json
            # Select the first release from the returned list, which is the latest
            $downloadUri = ($releaseData[0].assets | Where-Object name -like $FilenamePattern).browser_download_url
        }
        else {
            Write-Host "Searching for latest stable release..." -ForegroundColor Cyan
            $releasesUri = "https://api.github.com/repos/$Repo/releases/latest"
            # Get the raw JSON content and convert it to an object
            $releaseData = Invoke-WebRequest -Uri $releasesUri | Select-Object -ExpandProperty Content | ConvertFrom-Json
            $downloadUri = ($releaseData.assets | Where-Object name -like $FilenamePattern).browser_download_url
        }

        # Check if a download URI was found
        if ([string]::IsNullOrEmpty($downloadUri)) {
            throw "Could not find a download asset matching '$FilenamePattern' for repository '$Repo'."
        }

        # Define temporary file and extraction paths
        $pathZip = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath $(Split-Path -Path $downloadUri -Leaf)

        # Download the file
        Write-Host "Downloading release from $downloadUri" -ForegroundColor Green
        Invoke-WebRequest -Uri $downloadUri -OutFile $pathZip

        # Remove the existing destination directory to ensure a clean install
        if (Test-Path -Path $PathExtract) {
            Write-Host "Removing existing directory at $PathExtract" -ForegroundColor Yellow
            Remove-Item -Path $PathExtract -Recurse -Force
        }

        # Handle extraction based on the InnerDirectory switch
        if ($InnerDirectory) {
            Write-Host "Extracting to a temporary directory..." -ForegroundColor Green
            $tempExtract = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath $((New-Guid).Guid)
            Expand-Archive -Path $pathZip -DestinationPath $tempExtract -Force

            Write-Host "Moving contents from temporary directory to $PathExtract..." -ForegroundColor Green
            # This handles both a single folder and files at the root of the tempExtract
            $innerContents = Get-ChildItem -Path $tempExtract -Directory
            if ($innerContents.Count -eq 1) {
                # Assume a single top-level folder
                Move-Item -Path "$tempExtract\$($innerContents.Name)\*" -Destination $PathExtract -Force
            }
            else {
                # Assume files at the root
                Move-Item -Path "$tempExtract\*" -Destination $PathExtract -Force
            }
        }
        else {
            Write-Host "Extracting directly to $PathExtract..." -ForegroundColor Green
            Expand-Archive -Path $pathZip -DestinationPath $PathExtract -Force
        }

        # Clean up the downloaded zip file and temporary extraction directory
        Write-Host "Cleaning up temporary files..." -ForegroundColor Gray
        Remove-Item $pathZip -Force -ErrorAction SilentlyContinue
        if ($InnerDirectory -and (Test-Path -Path $tempExtract)) {
            Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "Download and extraction complete!" -ForegroundColor Green

    }
    catch {
        Write-Error "An error occurred: $_"
        # Clean up in case of an error
        Remove-Item $pathZip -Force -ErrorAction SilentlyContinue
        if ($InnerDirectory -and (Test-Path -Path $tempExtract)) {
            Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
