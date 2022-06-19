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

# install the requirements
RUN apk add --no-cache \
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
    curl

RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust

# Download the powershell '.tar.gz' archive
RUN curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/powershell-7.2.4-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz

# Create the target folder where powershell will be placed
RUN mkdir -p /opt/microsoft/powershell/7

# Expand powershell to the target folder
RUN tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

# Set execute permissions
RUN chmod +x /opt/microsoft/powershell/7/pwsh

# Create the symbolic link that points to pwsh
RUN ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# Install openssh package for Powershell Remoting over SSH
RUN apk add --no-cache openssh

# Install Atomicredteam
RUN pwsh -command "IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing); Install-AtomicRedTeam -getAtomics -Force;"

# Download Attire-ExecutionLogger
RUN mkdir -p ~/loggers
RUN curl -L https://raw.githubusercontent.com/SecurityRiskAdvisors/invoke-atomic-attire-logger/main/Attire-ExecutionLogger.psm1 -o ~/loggers/Attire-ExecutionLogger.psm1

# Load Invoke-AtomicRedTeam in profile
RUN mkdir -p ~/.config/powershell/
RUN echo -e 'Import-Module "/root/AtomicRedTeam/invoke-atomicredteam/Invoke-AtomicRedTeam.psd1" -Force\nImport-Module "/root/loggers/Attire-ExecutionLogger.psm1" -Force' > ~/.config/powershell/profile.ps1

# Cleanup
RUN rm /tmp/powershell.tar.gz

# Start PowerShell
ENTRYPOINT ["pwsh"]