#!/bin/bash

is_docker_active(){
  # Checking if dockerd is running
  if [[ $(systemctl is-active docker) == 'active' ]]; then
    true
  else
    echo -e "\n[+] Starting docker daemon"
    systemctl start docker -q
  fi 
}

# The script must be run as root because it requires docker
if [[ $UID -ne 0 ]]; then
  echo -e "[!] This script requires root privileges!"
  exit -1;
fi

echo -e "[+] Updating APT packages"
sudo apt update

echo -e "\n[+] Installing requirements"
sudo apt install -y sed curl openssl uuid-runtime coreutils

echo -e "\n[+] Checking if docker is installed"
if [[ $(uname -r) =~ "kali" ]]; then
  # Docker installation on Kali Linux
  if ! which docker >/dev/null; then
    echo -e "\n[+] Installing docker"
    apt install -y docker.io
    if [[ $? == 0 ]]; then echo -e "\n[+] Docker was successfully installed!"; else echo -e "\n[-] An error occured!"; fi
  else
    echo -e "\n[+] Docker is already installed!"
  fi
  echo -e "\n[+] Checking if docker-compose is installed"
  if ! which docker-compose >/dev/null; then
    echo -e "\n[+] Installing docker-compose"
    apt install -y docker-compose
    if [[ $? == 0 ]]; then echo -e "\n[+] Docker-compose was successfully installed!"; else echo -e "\n[-] An error occured!"; fi
  else
    echo -e "\n[+] Docker-compose is already installed!"
  fi
else
  # Docker installation for other Debian-based distributions
  if ! which docker >/dev/null ; then
    echo -e "\n[+] Installing docker"
    curl -fsSL https://get.docker.com | sudo bash
  else
    echo -e "\n[+] Docker is already installed!"
  fi
fi
is_docker_active

echo -e "\n[+] Downloading and running SysReptor\n"
bash <(curl -s https://docs.sysreptor.com/install.sh)
echo -e "\n[+] Access your application at http://127.0.0.1:8000/ and use the credentials provided above"
# Installing HTB and Offsec exams' template
read -p "[+] Would you like to install the reporting templates for HTB and Offsec? [Y/n] " choice
choice=${choice:-Y}
if [[ $choice == "Y" ]]; then
  if [[ -d sysreptor/deploy ]]; then
    cd sysreptor/deploy
    echo -e "[+] Downloading HTB reporting templates (CPTS, CBBH, CDSA, CWEE, CAPE)"
    curl -s "https://docs.sysreptor.com/assets/htb-designs.tar.gz" | docker compose exec --no-TTY app python3 manage.py importdemodata --type=design
    curl -s "https://docs.sysreptor.com/assets/htb-demo-projects.tar.gz" | docker compose exec --no-TTY app python3 manage.py importdemodata --type=project
    if [[ $? == 0 ]]; then
      echo -e "[+] HTB reporting templates successfully downloaded"
    else
      echo -e "\n[-] An error occured"
    fi
    echo -e "\n[+] Downloading Offsec reporting templates (OSCP, OSWP, OSEP, OSWA, OSWE, OSED, OSMR, OSEE, OSDA)"
    if [[ $? == 0 ]]; then
      curl -s "https://docs.sysreptor.com/assets/offsec-designs.tar.gz" | docker compose exec --no-TTY app python3 manage.py importdemodata --type=design
    else
      echo "[+] Offsec reporting templates successfully downloaded"
    fi
  else
    echo -e "\n[-] Unable to find SysReptor folder. Are you sure SysReptor is installed?"
  fi
fi

echo -e "\n[i] For more information, refer to https://docs.sysreptor.com"
