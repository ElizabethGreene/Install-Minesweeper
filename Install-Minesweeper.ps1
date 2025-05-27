
# Install-Minesweeper.ps1
# This script installs Windows XP's Minesweeper on Windows 10 or 11 by extracting the files from the Windows XP CD or ISO.
# 
# Minimal Instructions: Insert a Windows XP CD or right-click and mount the ISO.
# Note the path to the /i386 folder.
# Run this script as an administrator with that source path as the parameter.
# Install-Minesweeper.ps1 -SourcePath D:\i386
# This installs the Minesweeper game to C:\Program Files (x86)\Minesweeper
# and creates Start menu shortcut.
# 
# Optional instructions. 
# To install without administrator rights, specify a user writable destination folder 
# with the -DestinationFolder parameter
# Install-Minesweeper.ps1 -SourcePath D:\i386 -DestinationFolder "C:\users\egreene\Minesweeper"
# 
# Elizabeth Greene 2025 <elizabeth.a.greene@gmail.com>
# v1.0
# https://github.com/ElizabethGreene/Install-Minesweeper
#
# License details:
# Microsoft's Minesweeper is not free software.  To install and run it you should have a license from Microsoft.
# This installer program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
##############################################################################
param (
    [Parameter(Mandatory = $true)]
    [string]$SourcePath = "D:\i386",
    [string]$DestinationFolder = "C:\Program Files (x86)\Minesweeper"
)

$isadmin = $false
# Check if the script is running elevated/as an administratorand warn about the destination folder.
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $isadmin = $true
} else {
    if ($DestinationFolder -eq "C:\Program Files (x86)\Minesweeper") {
        Write-Host "This script must be run as an administrator to install to $DestinationFolder" -ForegroundColor Red
        Write-Host "To install without administrator rights, specify a user writable destination folder with the -DestinationFolder parameter." -ForegroundColor Yellow
        Write-Host "e.g. Install-Minesweeper.ps1 -SourcePath $SourcePath -DestinationFolder C:\users\egreene\Minesweeper" -ForegroundColor Yellow
        exit
    }
}


# Check if the source path exists
if (-not (Test-Path $SourcePath)) {
    Write-Host "Source path not found: $SourcePath" -ForegroundColor Red
    exit
}

# Define the list of files
$FileList = @(
    "WINMINE.EXE"
)

# Use the file list to create a hash table to store the compressed and uncompressed file names.
$RequiredFiles = @{}
# Example: Font.dat is Wfont.da_ in the source path.
$FileList | ForEach-Object {
    #Replace the last character with an underscore and add a W to the beginning.
    $RequiredFiles[$_] = "W" + $_.Substring(0, $_.Length - 1) + "_"
}

# Check if the required files are present in the source path.
$MissingFiles = $RequiredFiles.Values | Where-Object { -not (Test-Path "$SourcePath\$_") }

if ($MissingFiles.Count -gt 0) {
    Write-Host "The following required files were not found in the source path:" -ForegroundColor Red
    $MissingFiles | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit
}

# Make the Destination folder exists, and create it if it does not already exist.
if (-not (Test-Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
}

# Use the built-in Windows expand command to extract the files and then rename them to the correct filename
# Example: expand g:\i386\Wfont.da_ -F:font.dat "C:\Program Files (x86)\Minesweeper"
# creates wfont.da_ in the destination and then we rename it to font.dat

foreach ($DestinationFile in $RequiredFiles.Keys) {
    $SourceFile = "$SourcePath\$($RequiredFiles[$DestinationFile])"
    Write-Host "Expanding $SourceFile to $DestinationFolder"
    expand $SourceFile -F:$DestinationFile "$DestinationFolder"
    # Rename the file to the correct name.
    Rename-Item "$DestinationFolder\$($RequiredFiles[$DestinationFile])" "$DestinationFolder\$DestinationFile"
}

# Create a start menu shortcut
if (-not $SkipStartMenuShortcut) {

    # The default destination folder is the All Users start menu folder.
    $ShortcutFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"

    #... but if the script is not running as an administrator, use the user's start menu folder.
    if (-not $isadmin) {
        $ShortcutFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    }
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$ShortcutFolder\Minesweeper.lnk")
    $Shortcut.TargetPath = "$DestinationFolder\Winmine.exe"
    $Shortcut.Save()
}
