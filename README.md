## Summary
### OS : ubuntu 20.04, ubuntu 22.04
### k8s : 1.24.6
### cni : flannel
### cri : containerd
-------------------------------
## how to enter dashboard
### 1. enter >> kubectl create token -n kube-system admin-user
### 2. copy the token then paste it to the browser
-------------------------------
## parameters relevant with nodes
### add worker
### - hosts.yml에 추가할 노드 명시
### - facts.yml
### - scale.yml
### - (optional) scale.yml --limit=추가할 노드 이름

### add control plane
### - hosts.yml에 추가할 노드 명시
### - cluster.yml

### add etcd
### - cluster.yml --limit=etcd,kube_control_plane -e ignore_assert_errors=yes
### - upgrade-cluster.yml --limit=etcd,kube_control_plane -e ignore_assert_errors=yes
### - 모든 control plane 노드에서 /etc/kubernetes/manifests/kube-apiserver.yaml 안의 --etcd-servers 파라미터에 새로운 etcd를 명시

### remove worker/control plane
### - hosts.yml에는 삭제할 노드 명시
### - remove-node.yml -e node=NODE_NAME
### - (offline) remove-node.yml -e node=NODE_NAME -e reset_nodes=false -e allow_ungraceful_removal=true
### - hosts.yml에서 삭제된 노드 제거

### remove etcd
### - hosts.yml에는 삭제할 노드 명시
### - remove-node.yml -e node=NODE_NAME
### - (offline) remove-node.yml -e node=NODE_NAME -e reset_nodes=false -e allow_ungraceful_removal=true
### - hosts.yml에서 삭제된 노드 제거
### - cluster.yml >> 모든 노드에 설정 파일 재생성
### - 모든 control plane 노드에서 /etc/kubernetes/manifests/kube-apiserver.yaml 안의 --etcd-servers 파라미터에 삭제된 etcd 정보 제거
