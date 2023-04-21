#-----------------------------------
#
# do not run this script as root
#
#-----------------------------------

#!/bin/bash

IP=

# prerequisite
cd ~

# disable firewall
sudo systemctl stop ufw
sudo systemctl disable ufw

# install basic packages
sudo apt install -y python3-pip

# network configuration
sudo modprobe overlay \
    && sudo modprobe br_netfilter

cat <<EOF | sudo tee -a /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee -a /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# ssh configuration
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa ${USER}@${IP}

# k8s installation via kubespray
git clone https://github.com/kubernetes-sigs/kubespray.git -b release-2.19
cd kubespray
pip install -r requirements.txt

echo "export PATH=${HOME}/.local/bin:${PATH}" >> ~/.bashrc
source ~/.bashrc

cp -rfp inventory/sample inventory/mycluster
declare -a IPS=(${IP})
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

#sed -i "s/docker_version: '20.10'/docker_version: 'latest'/g" roles/container-engine/docker/defaults/main.yml
#sed -i "s/docker_containerd_version: 1.4.12/docker_containerd_version: latest/g" roles/download/defaults/main.yml

sed -i "s/container_manager: containerd/container_manager: docker/g" roles/kubespray-defaults/defaults/main.yaml
sed -i "s/container_manager: containerd/container_manager: docker/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
#sed -i "s/# container_manager: containerd/container_manager: docker/g" inventory/mycluster/group_vars/all/etcd.yml
#sed -i "s/etcd_deployment_type: containerd/etcd_deployment_type: docker/g" inventory/mycluster/group_vars/all/etcd.yml

sed -i "s/host_architecture }}]/host_architecture }} signed-by=\/etc\/apt\/keyrings\/docker.gpg]/g" roles/container-engine/docker/vars/ubuntu.yml

#sed -i "s/# cri_dockerd_enabled: false/cri_dockerd_enabled: true/g" inventory/mycluster/group_vars/all/docker.yml
#sed -i "s/cri_dockerd_enabled: false/cri_dockerd_enabled: true/g" roles/kubespray-defaults/defaults/main.yaml

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# enable kubectl & kubeadm auto-completion
echo "source <(kubectl completion bash)" >> ${HOME}/.bashrc
echo "source <(kubeadm completion bash)" >> ${HOME}/.bashrc
echo "source <(kubectl completion bash)" | sudo tee -a /root/.bashrc
echo "source <(kubeadm completion bash)" | sudo tee -a /root/.bashrc
source ${HOME}/.bashrc

ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml -K
sleep 120
cd ~

# enable kubectl in admin account and root
mkdir -p ${HOME}/.kube
sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
sudo chown ${USER}:${USER} ${HOME}/.kube/config

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# install helmfile
wget https://github.com/helmfile/helmfile/releases/download/v0.150.0/helmfile_0.150.0_linux_amd64.tar.gz
tar -zxvf helmfile_0.150.0_linux_amd64.tar.gz
sudo mv helmfile /usr/bin/
rm LICENSE && rm README.md && rm helmfile_0.150.0_linux_amd64.tar.gz

# how to enter dashboard

# how to add master, worker nodes

# how to remove master, worker nodes

# how to upgrade cluster

# how to change variables in ansible config files
