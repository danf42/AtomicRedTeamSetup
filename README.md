# Invoke-Atomicredteam Environment Setup

This project creates a container to use Invoke-Atomicredteam remotely against targets by establishing a PowerShell Remoting session over SSH.

Two scripts have been created to setup PowerShell Remoting over SSH on the target hosts (Windows and Linxu).  

## Setup

### Prequists 
- (C2 Host) Docker is required for Windows/Linux host running the Invoke-Atomicredteam container. 
- (Target Host) A user must be created with a password in order to use PowerShell Remoting

### Comand and Control Host
1. Ensure Docker is installed and running

2. To build the container

    `docker build -t atomicred .`

3. Run the container

    `docker run -it --name atomic-red atomicred`

4. Start a remote session

    `$sess = New-PSSession -HostName <ip address/hostname> -Username <username>`

#### Web Services for Management (WSMan) Support
If WSMan support is required for remote connections the docker file based on debian is required

1. Ensure Docker is installed and running

2. Build Dockerfile based on debian

    `docker build -t atomicred -f .\Dockerfile.debian .`

3. Run the container 

    `docker run -it --name atomic-red atomicred`

4. Start a remote session

    `$sess = New-PSSession -ComputerName <ip address/hostname> -Credential <username> -Authentication Negotiate`

### Target Host
Target hosts need to be configured to accept PowerShell Remoting sessions over SSH.  

For x64 Windows OS Hosts:
1. From an elevated PowerShell prompt run, `setupPSRemoting.ps1` 

For x64 Linux Hosts:
- From an elevated command prompt run, `setupPSRemoting.sh`

## Usage
### Creating Remote Session
1. Establish remote sesion from the server (docker container) to the target client host

    ```powershell
    $sess = New-PSSession -HostName <ip address/hostname> -Username <username> -Name <friendlyname>
    ```

2. Verify session is established
    ```powershell
    Get-PSSession
    Invoke-Command -Session $sess -ScriptBlock {Get-Process}
    ```

### Verify Invoke-Atomicredteam
1. Install any prerequisites on the remote machine before executing the test

    ```powershell
    Invoke-AtomicTest T1218.010 -Session $sess -GetPrereqs
    ```

2. Execute all atomic tests in technique T1218.010 on a remote machine

    ```powershell
    Invoke-AtomicTest T1218.010 -Session $sess
    ```

3. Cleanup from the test

    ```powershell
    Invoke-AtomicTest T1218.010 -Cleanup -Session $sess
    ```

### Logging in Vectr format with Attire-ExecutionLogger
1. Create a mount point when starting the docker container

    `docker run -it -v "$(pwd)"/logs:/logs --name atomic-red atomicred`

2. Execute atomic test with Attire logging module

    `Invoke-AtomicTest T1087.001 -LoggingModule "Attire-ExecutionLogger" -ExecutionLogPath "/logs/attireLog.json" -Session $sess`

## Useful Links
- [Invoke-Atomicredteam Wiki](https://github.com/redcanaryco/invoke-atomicredteam/wiki)
- [Atomic Red Team YouTube Tutorial Series](https://www.youtube.com/playlist?list=PL92eUXSF717W9TCfZzLca6DmlFXFIu8p6)
- [Invoke-atomic-attire-logger](https://github.com/SecurityRiskAdvisors/invoke-atomic-attire-logger)
- [Install PowerShell on Windows, Linux, and macOS](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.2)
- [PowerShell remoting over SSH](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/ssh-remoting-in-powershell-core?view=powershell-7.2)