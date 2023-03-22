#-----------------------------------
#
# do not run this script as root
#
#-----------------------------------

#!/bin/bash

IP=

# prerequisite
cd ~
sudo sed -i 's/1/0/g' /etc/apt/apt.conf.d/20auto-upgrades
sudo apt install -y net-tools python3-pip

sudo systemctl stop ufw
sudo systemctl disable ufw

ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa ${USER}@${IP}

git clone https://github.com/kubernetes-sigs/kubespray.git -b release-2.20

cd kubespray
pip install -r requirements.txt
echo "export PATH=${HOME}/.local/bin:${PATH}" >> ~/.bashrc
source ~/.bashrc
cp -rfp inventory/sample inventory/mycluster
declare -a IPS=(${IP})
#CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

#ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml

# deploy kubespray

# how to enter dashboard

# how to add master, worker nodes

# how to remove master, worker nodes

# how to upgrade cluster

# how to change variables in ansible config files
