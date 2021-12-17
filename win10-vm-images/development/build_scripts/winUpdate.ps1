## Install Windows Updates
# This script will install all prereqs and install
# All available Windows updates. The installation will
# run completly silently and not require any interaction.

# Packer runs the PowerShell session with 'Bypass'
#Set-ExecutionPolicy RemoteSigned -Scope currentuser -Force

Install-PackageProvider -Name NuGet -Force -confirm:$false
install-Module -Name PSWindowsUpdate -Force -confirm:$false

Import-Module -Name PSWindowsUpdate

# List available Windows Updates
Get-WUList | format-table

# Export info on installed update to c:\
$availableUpdates = Get-WUList
$availableUpdates | select-Object KB, Size, Title | Export-csv -path C:\InstalledUpdates.csv -noTypeInformation

# Install ALL available Windows Updates
Install-WindowsUpdate -AcceptAll -Verbose -Confirm:$false
