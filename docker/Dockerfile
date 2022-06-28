###############################################################################
#
# This dockerfile will build a container for Invoke-Atomicredteam
#
# Usage:
# Build the container
# > docker build -t pwsh .
#
# Run container - Delete on exit
# > docker run -it --rm pwsh
# 
# Run container - Persist on exit
# > docker run -it --name mypwsh pwsh
# > docker start -i mypwsh
#
# Verify Invoke-Atomicredteam module was importated successfully
# > Invoke-AtomicTest T1113 -ShowDetails
#
###############################################################################

FROM alpine:3.14

# 
ENV PWS_VER=7.2.5

# install the requirements
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl \
    openssh

# Install PowerShell core
RUN curl -L https://github.com/PowerShell/PowerShell/releases/download/v${PWS_VER}/powershell-${PWS_VER}-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    rm /tmp/powershell.tar.gz

# Install Atomicredteam, Attire-ExecutionLogger, and Load Invoke-AtomicRedTeam in profile
RUN pwsh -command "IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing); Install-AtomicRedTeam -getAtomics -Force;" && \
    mkdir -p ~/loggers && \
    curl -L https://raw.githubusercontent.com/SecurityRiskAdvisors/invoke-atomic-attire-logger/main/Attire-ExecutionLogger.psm1 -o ~/loggers/Attire-ExecutionLogger.psm1 && \
    mkdir -p ~/.config/powershell/ && \
    echo -e 'Import-Module "/root/AtomicRedTeam/invoke-atomicredteam/Invoke-AtomicRedTeam.psd1" -Force\nImport-Module "/root/loggers/Attire-ExecutionLogger.psm1" -Force' > ~/.config/powershell/profile.ps1

# Start PowerShell
ENTRYPOINT ["pwsh"]