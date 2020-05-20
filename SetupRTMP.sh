#!/bin/bash
###	This file should be run in SUDO mode

resourceGroupName=$1
storageAccountName=$2
containerName=$3
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

mkdir /mnt/$containerName -p
chown sysadmin:adm /mnt/$containerName

if [ ! -d "/etc/tvfeedsconnect" ]; then
sudo mkdir /etc/tvfeedsconnect
fi
sudo bash -c 'echo "accountName '$storageAccountName'" >> /etc/tvfeedsconnect/tvfeeds.cfg'
sudo bash -c 'echo "accountKey  '$AccessKey'" >> /etc/tvfeedsconnect/tvfeeds.cfg'
sudo bash -c 'echo "authType Key" >> /etc/tvfeedsconnect/tvfeeds.cfg'
sudo bash -c 'echo "containerName '$containerName'" >> /etc/tvfeedsconnect/tvfeeds.cfg'

chmod sysadmin:adm /etc/tvfeedsconnect/tvfeeds.cfg

mkdir /home/sysadmin/$containerName
chown sysadmin:adm /home/sysadmin/$containerName
blobfuse /home/sysadmin/$containerName --tmp-path=/mnt/$containerName -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/etc/tvfeedsconnect/tvfeeds.cfg --log-level=LOG_DEBUG --file-cache-timeout-in-seconds=120


touch /home/sysadmin/mount.sh
chown sysadmin:adm /home/sysadmin/mount.sh

bash -c 'echo "#!/bin/bash >> /home/sysadmin/mount.sh'
bash -c 'echo "BLOBFS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" >> /home/sysadmin/mount.sh'
bash -c 'echo "cd $BLOBFS_DIR/build >> /home/sysadmin/mount.sh'
bash -c 'echo "/blobfuse $1 --tmp-path=/mnt/tvfeeds -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/etc/blobconnect.cfg >> /home/sysadmin/mount.sh'

chmod +x /home/sysadmin/mount.sh

bash -c 'echo "/home/sysadmin/mount.sh /mnt/tvfeeds fuse _netdev >> /etc/fstab'

./azcopy copy 'https://learnadminfiles.blob.core.windows.net/adminfiles/Dockerfile' .
./azcopy copy 'https://learnadminfiles.blob.core.windows.net/adminfiles/nginx.conf' .

if [ ! -d "/home/sysadmin" ]; then
mkdir /home/sysadmin
fi

cp Dockerfile /home/sysadmin
cp nginx.conf /home/sysadmin

cd /home/sysadmin

docker build --tag=c9rtmp .
docker run -p 1935:1935 -p 8080:8080 -v "/home/sysadmin/$containerName:/data" --restart unless-stopped --detach c9rtmp

usermod -aG docker sysadmin
