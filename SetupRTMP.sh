#!/bin/bash

###	This file should be run in SUDO mode

### The script file needs to be executable, i.e.
#	chmod +x script.sh

TOKEN="52874c0fa8552059adfc92295c5265b659f6948c"
OWNER="sethjuarez"
REPO="LearnTV"

resourceGroupName="WestUS2-Learn-TV"
storageAccountName="saltvd2nujec4q2mpk"
fileShareName="fssaltvd2nujec4q2mpk"
AccessKey="xitGcFvf0PRE63i8OlrBH4TeLBJ1g2PoB9Djl70kcVAbUZBAhEsKMOQ1csDOJ80UUWVtdhgf2EdeGgGWzLIF4w=="

#	Update package index
apt-get update
apt install cifs-utils

sudo mkdir /mnt/$fileShareName
if [ ! -d "/etc/smbcredentials" ]; then
sudo mkdir /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/$fileShareName.cred" ]; then
    sudo bash -c 'echo "username='$fileShareName'" >> /etc/smbcredentials/'$fileShareName'.cred'
    sudo bash -c 'echo "password='$AccessKey'" >> /etc/smbcredentials/'$fileShareName'.cred'
fi
sudo chmod 600 /etc/smbcredentials/saltvd2nujec4q2mpk.cred

sudo bash -c 'echo "//'$fileShareName'.file.core.windows.net/'$fileShareName' /mnt/'$fileShareName' cifs nofail,vers=3.0,credentials=/etc/smbcredentials/'$fileShareName'.cred,dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab'
sudo mount -t cifs //$storageAccountName.file.core.windows.net/$fileShareName /mnt/$fileShareName -o vers=3.0,credentials=/etc/smbcredentials/saltvd2nujec4q2mpk.cred,dir_mode=0777,file_mode=0777,serverino

#	Install tools
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

#	Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

#	Setup stable repo
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

#	Update package index (again)
apt-get update

#	Install latest version of Docker CE
apt-get install docker-ce -y

PATH="LearnTV/server/Dockerfile"
FILE="https://api.github.com/repos/$OWNER/$REPO/contents/$PATH"

curl --header 'Authorization: token $TOKEN' \
     --header 'Accept: application/vnd.github.v3.raw' \
     --remote-name \
     --location $FILE

PATH="LearnTV/server/nginx.conf"
FILE="https://api.github.com/repos/$OWNER/$REPO/contents/$PATH"

curl --header 'Authorization: token $TOKEN' \
     --header 'Accept: application/vnd.github.v3.raw' \
     --remote-name \
     --location $FILE

# Sudo docker build --tag=c9restream .
docker run -p 1935:1935 -p 8080:8080 -v "/mnt/$fileShareName:/data" --detach c9rtmp --restart unless-stopped

# sudo usermod -aG docker ${USER}


