#!/bin/bash

# set terminal output colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

if [ `whoami` != root ]; then
    echo "${RED}[!] Please run this script as root or using sudo ${RESET}"
    exit
fi

echo "${BLUE}[*] Updating packages ${RESET}"
apt update && apt upgrade -y

echo "${BLUE}[*] Install dependency packages ${RESET}"
apt install -y curl

echo "${BLUE}[*] Installing powershell core ${RESET}"
curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/powershell-lts_7.2.5-1.deb_amd64.deb -o /tmp/powershell.deb
dpkg -i /tmp/powershell.deb
rm /tmp/powershell.deb

FILE=/usr/bin/pwsh
if [[ -f "$FILE" ]]; then
    echo "${GREEN}[+] PowershellCore successfully installed ${RESET}"

else
    echo "${RED}[!] PowershellCore failed to installed ${RESET}"
    echo "${RED}[!] Installer will exit... ${RESET}"
    exit
fi

echo "${BLUE}[*] Install and Configure SSH ${RESET}"
apt install -y openssh-server openssh-client

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bkup

cat <<EOT > /etc/ssh/sshd_config
Include /etc/ssh/sshd_config.d/*.conf

PasswordAuthentication yes
ChallengeResponseAuthentication no

UsePAM yes

X11Forwarding yes

PrintMotd no

AcceptEnv LANG LC_*

Subsystem	sftp	   /usr/lib/openssh/sftp-server
Subsystem   powershell /usr/bin/pwsh -sshs -NoLogo

EOT

echo "${BLUE}[*] Restart SSHD Service ${RESET}"
systemctl restart sshd.service

is_running=`systemctl status sshd | grep -c 'running'`
if [[ 1 -eq $is_running ]]; then
    echo "${GREEN}[+] SSHD is running ${RESET}"

else
    echo "${RED}[!] SSHD Is not running.  Please verify status ${RESET}"
fi