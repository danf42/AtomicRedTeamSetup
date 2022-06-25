$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "[!] Need to run script in Administrator terminal" -ErrorAction Stop
}

<#
Download and install PowerShell
Instructions are from https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7#msi
#>

# Download and Install PowerShell Core
Write-Host "[*] Downloading PowerShell"

$soureFile = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/PowerShell-7.2.5-win-x64.msi'
$destinationFile = $env:temp + '\powershell.msi'

#Invoke-WebRequest -Uri $soureFile -OutFile $destinationFile
Start-BitsTransfer -Source $soureFile -Destination $destinationFile

if (Test-Path -Path $destinationFile) {
    "[+] Successfully downloaded to " + $destinationFile
} else {
	Write-Error "[!] Failed to download powershell installer" -ErrorAction Stop
}

Write-Host "[*] Installing PowerShell"
Start-Process msiexec.exe -Wait -ArgumentList "/package $destinationFile /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1"

# Verify PowerShell Core installed
$psCorePath = $env:ProgramFiles + '\PowerShell\7'
if (Test-Path -Path $psCorePath) {
    "[+] PowerShell Core Installed Successfully"
} else {
	Write-Error "[!] Failed to install PowerShell" -ErrorAction Stop
}

<#
Download and Install OpenSSH Client and Server
Instructions are from https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/ssh-remoting-in-powershell-core?view=powershell-7
#>
 
# Download and Install OpenSSh
Write-Host "[*] Download and Install OpenSSh"

# Install the OpenSSH Client
$job = Start-Job -ScriptBlock {Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0}
$job | Wait-Job

# Install the OpenSSH Server
$job = Start-Job -ScriptBlock {Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0}
$job | Wait-Job

# Verify SSH client was installed
$isInstalled = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*' | Select-Object State

if ("Installed" -eq $isInstalled.State) {
	Write-Host "[+] OpenSSH.Client successfully installed"
} else {
	Write-Error "[!] OpenSSH.Client failed to install" -ErrorAction Stop
}

# verify SSH server was installed
$isInstalled = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Select-Object State

if ("Installed" -eq $isInstalled.State) {
	Write-Host "[+] OpenSSH.Server successfully installed"
} else {
	Write-Error "[!] OpenSSH.Server failed to install" -ErrorAction Stop
}

# Start the sshd service
Start-Service sshd

$sshStatus = (Get-Service sshd).Status
if ( "Running" -eq $sshStatus){
	Write-Host "[+] SSH is running"
} else {
	Write-Error "[!] SSH Service is not running.  Exiting install..." -ErrorAction Stop
}

# OPTIONAL but recommended:
Set-Service -Name sshd -StartupType 'Automatic'

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "[*] Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "[*] Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}

# Edit sshd_config file
Write-Host "[*] Edit sshd_config file"

$sshdConfigFile = $env:ProgramData + '\ssh\sshd_config'
Copy-Item $sshdConfigFile -Destination "$sshdConfigFile.bkup"

$sshConfigUpdate = @"
AuthorizedKeysFile       .ssh/authorized_keys
PasswordAuthentication    yes

Subsystem     sftp        sftp-server.exe
Subsystem     powershell  c:/progra~1/powershell/7/pwsh.exe -sshs -NoLogo

Match Group administrators
     AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
"@

$sshConfigUpdate | Out-file -FilePath $sshdConfigFile -Encoding utf8

Write-Host "[*] Restart ssh service"
Restart-Service sshd

$sshStatus = (Get-Service sshd).Status
if ( "Running" -eq $sshStatus){
	Write-Host "[+] SSH is running"
} else {
	Write-Host "[!] SSH is not running"
}


# Cleanup
Remove-Item -Path $destinationFile