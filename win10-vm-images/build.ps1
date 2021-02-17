# Set execution policy. Reset during Sysprep
#Set-ExecutionPolicy Unrestricted

###
# Check for available Windows Updates
###
# # Install nuget package managed
# Install-PackageProvider -Name NuGet -Force
# # Install PS Windows Update module
# Install-Module PSWindowsUpdate -force

# # Query for available Windows Updates
# #Get-WindowsUpdate
# Get-WUList
# # Install available windows update
# Install-WindowsUpdate -AcceptAll

###
# Install developer tools from Chocolaty
###

# Install Choco
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install visual studio code (choco)
choco install vscode --confirm
# Install visual studio 2019 CE (choco)
#choco install visualstudio2019community --confirm
# Install Google Chrome
choco install googlechrome --confirm
# Install git
choco install git.install --confirm
# Install putty
choco install putty.install --confirm
# Install Azure Powershell Module (AZ)
choco install az.powershell --confirm
# Install Azure CLI
choco install azure-cli --confirm
# Install Azure Storage Explorer
choco install microsoftazurestorageexplorer --confirm
# Install AzCopy
choco install azcopy --confirm
# Install WVD Agent
choco install wvd-agent --confirm


 
 # Sysprep - Generalize virtual machine (Required)
 while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }
 while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }
 & $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit
 while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | `
         Select-Object ImageState; `
                if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } `
                else { break } }