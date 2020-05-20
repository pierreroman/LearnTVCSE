#!/bin/bash
###	This file should be run in SUDO mode

resourceGroupName=$1
storageAccountName=$2
fileShareName=$3
AccessKey=$4

#	Update package index
apt-get update
apt install cifs-utils -y

curl -s -D- https://aka.ms/downloadazcopy-v10-linux | grep ^Location
wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-add-repository https://packages.microsoft.com/ubuntu/18.04/prod
sudo apt-get update
apt-get install blobfuse
apt install docker.io -y


./azcopy copy 'https://learnadminfiles.blob.core.windows.net/adminfiles/Dockerfile' .
./azcopy copy 'https://learnadminfiles.blob.core.windows.net/adminfiles/nginx.conf' .

if [ ! -d "/home/sysadmin" ]; then
mkdir /home/sysadmin
fi

cp Dockerfile /home/sysadmin
cp nginx.conf /home/sysadmin

cd /home/sysadmin

docker build --tag=c9rtmp .
#docker run -p 1935:1935 -p 8080:8080 -v "/mnt/saltv1fwfinzhrtysgc:/data" --restart unless-stopped --detach c9rtmp

usermod -aG docker sysadmin
