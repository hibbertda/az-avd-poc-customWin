$connectTestResult = Test-NetConnection -ComputerName saavdimagesource1112.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"saavdimagesource1112.file.core.windows.net`" /user:`"localhost\saavdimagesource1112`" /pass:`"layPFIbG+t0UbFrCJV3TFOG9cAF9AEWrnrM8rKrJ4Ftzkmlpp015fBJhzC0PUwN0C1ArMOgAXvDNCgRqvsDBEg==`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\saavdimagesource1112.file.core.windows.net\software" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. "
}

# Install SQL Server Management Studio
cd z:/SSMS
./SSMS-Setup-ENU.exe /install /quiet /norestart

while (!(get-process ssms-setup-enu -ErrorAction SilentlyContinue)) { 
    write-Output -Message "SSMS install in-progress"
    start-Sleep -s 5 
}

# Install VSCode
cd z:/vscode-system
.\VSCodeSetup-x64-1.59.0.exe /VERYSILENT /MERGETASKS=!runcode

while (!(get-process VSCode* -ErrorAction SilentlyContinue)) { 
    write-Output -Message "SSMS install in-progress"
    start-Sleep -s 5 
}