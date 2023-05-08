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
sudo apt update
sudo apt install -y python3-pip nfs-common

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
git clone -b release-2.20 https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
pip install -r requirements.txt

echo "export PATH=${HOME}/.local/bin:${PATH}" | sudo tee ${HOME}/.bashrc > /dev/null
export PATH=${HOME}/.local/bin:${PATH}
source ${HOME}/.bashrc

cp -rfp inventory/sample inventory/mycluster
declare -a IPS=(${IP})
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# use docker container runtime
sed -i "s/docker_version: '20.10'/docker_version: 'latest'/g" roles/container-engine/docker/defaults/main.yml
sed -i "s/docker_containerd_version: 1.6.4/docker_containerd_version: latest/g" roles/download/defaults/main.yml
sed -i "s/container_manager: containerd/container_manager: docker/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i "s/# container_manager: containerd/container_manager: docker/g" inventory/mycluster/group_vars/all/etcd.yml
sed -i "s/host_architecture }}]/host_architecture }} signed-by=\/etc\/apt\/keyrings\/docker.gpg]/g" roles/container-engine/docker/vars/ubuntu.yml
sed -i "s/# docker_cgroup_driver: systemd/docker_cgroup_driver: systemd/g" inventory/mycluster/group_vars/all/docker.yml
sed -i "s/etcd_deployment_type: host/etcd_deployment_type: docker/g" inventory/mycluster/group_vars/all/etcd.yml
sed -i "s/# docker_storage_options: -s overlay2/docker_storage_options: -s overlay2/g" inventory/mycluster/group_vars/all/docker.yml
# download docker gpg
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# change network plugin as flannel
sed -i "s/kube_network_plugin: calico/kube_network_plugin: flannel/g" roles/kubespray-defaults/defaults/main.yaml
sed -i "s/kube_network_plugin: calico/kube_network_plugin: flannel/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

# enable nvidia container acceleration
sed -i "s/# nvidia_accelerator_enabled: true/nvidia_accelerator_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
# install nvidia driver
echo "docker_storage_options: -s overlay2" >> inventory/mycluster/group_vars/all/all.yml
sed -i "s/# nvidia_gpu_nodes:/nvidia_gpu_nodes:/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i "s/#   - kube-gpu-001/  - node1/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i "s/# nvidia_driver_version: \"384.111\"/nvidia_driver_version: \"384.111\"/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i "s/# nvidia_gpu_flavor: gtx/nvidia_gpu_flavor: gtx/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i "s/# nvidia_driver_install_ubuntu_container: gcr.io\/google-containers\/ubuntu-nvidia-driver-installer@sha256:7df76a0f0a17294e86f691c81de6bbb7c04a1b4b3d4ea4e7e2cccdc42e1f6d63/nvidia_driver_install_ubuntu_container: gcr.io\/google-containers\/ubuntu-nvidia-driver-installer@sha256:7df76a0f0a17294e86f691c81de6bbb7c04a1b4b3d4ea4e7e2cccdc42e1f6d63/g" inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

# enable dashboard / disable dashboard login / change dashboard service as nodeport
sed -i "s/# dashboard_enabled: false/dashboard_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml
sed -i "s/dashboard_skip_login: false/dashboard_skip_login: true/g" roles/kubernetes-apps/ansible/defaults/main.yml
sed -i'' -r -e "/targetPort: 8443/a\  type: NodePort" roles/kubernetes-apps/ansible/templates/dashboard.yml.j2

# enable helm
sed -i "s/helm_enabled: false/helm_enabled: true/g" inventory/mycluster/group_vars/k8s_cluster/addons.yml

# enable kubectl & kubeadm auto-completion
echo "source <(kubectl completion bash)" >> ${HOME}/.bashrc
echo "source <(kubeadm completion bash)" >> ${HOME}/.bashrc
echo "source <(kubectl completion bash)" | sudo tee -a /root/.bashrc
echo "source <(kubeadm completion bash)" | sudo tee -a /root/.bashrc
source ${HOME}/.bashrc

ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml -K
sleep 30
cd ~

# enable kubectl in admin account and root
mkdir -p ${HOME}/.kube
sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
sudo chown ${USER}:${USER} ${HOME}/.kube/config

# create sa and clusterrolebinding of dashboard to get cluster-admin token
kubectl apply -f ~/kubespray_ubuntu/sa.yaml
kubectl apply -f ~/kubespray_ubuntu/clusterrolebinding.yaml
