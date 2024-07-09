#!/bin/sh
##Extend LVM to all free space

lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

##stop ufw
systemctl stop ufw

##stop needrestart
grep "\$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf 
RESULT=$(echo $?)
if [ $RESULT -eq 0 ]; then
        echo "needrestart is already stop"
else 
        echo "\$nrconf{restart} = 'a'; " >>/etc/needrestart/needrestart.conf
fi

##Install NVIDIA driver in DKMS flavour from official repo
ls -ltrh /opt | grep cuda-keyring_1.1-1_all.deb
RESULT_cuda=$(echo $?)
if [ $RESULT_cuda -eq 0 ]; then
        echo "cuda-deb has been download in /opt"
else
        wget -P /opt/  https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
fi
dpkg -i /opt/cuda-keyring_1.1-1_all.deb
apt update
apt install -y cuda-drivers
apt install dkms
apt upgrade
##install MLNX_OFED
ls -ltrh /opt | grep MLNX_OFED_LINUX-5.8-4.1.5.0-ubuntu22.04-x86_64.tgz
RESULT_MLNX=$(echo $?)
if [ $RESULT_MLNX -eq 0 ]; then
        echo "MLNX_OFED has been download in /opt"
else
        wget -P /opt/  http://111.15.173.216:36666/mellanox/MLNX_OFED_LINUX-5.8-4.1.5.0-ubuntu22.04-x86_64.tgz
fi
tar -zxvf /opt/MLNX_OFED_LINUX-5.8-4.1.5.0-ubuntu22.04-x86_64.tgz -C /opt
/opt/MLNX_OFED_LINUX-5.8-4.1.5.0-ubuntu22.04-x86_64/mlnxofedinstall
cat << EOF
y
EOF
/etc/init.d/openibd restart
systemctl start opensm

## Install NVIDIA NVLink service
apt-get install -y  datacenter-gpu-manager cuda-drivers-fabricmanager
systemctl enable nvidia-fabricmanager