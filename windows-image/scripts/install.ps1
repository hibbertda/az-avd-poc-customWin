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

choco install rsat --confirm

choco install powerbi --confirm

choco install python --confirm

choco install vscode-python --confirm

choco install sql-server-management-studio --confirm

