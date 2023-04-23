## Summary
### OS : ubuntu 20.04, ubuntu 22.04
### k8s : 1.24.6
### cni : flannel
### cri : containerd
### kubespray : release-2.20
-------------------------------
## how to enter dashboard
### 1. enter >> kubectl create token -n kube-system admin-user
### 2. copy the token then paste it to the browser
-------------------------------
## how to add worker
### - hosts.yml에 추가할 노드 명시
### - facts.yml
### - scale.yml
### - (optional) scale.yml --limit=추가할 노드 이름
-------------------------------
## how to add control plane
### - hosts.yml에 추가할 노드 명시
### - cluster.yml
-------------------------------
## how to add etcd
### - cluster.yml --limit=etcd,kube_control_plane -e ignore_assert_errors=yes
### - upgrade-cluster.yml --limit=etcd,kube_control_plane -e ignore_assert_errors=yes
### - 모든 control plane 노드에서 /etc/kubernetes/manifests/kube-apiserver.yaml 안의 --etcd-servers 파라미터에 새로운 etcd를 명시
-------------------------------
## how to remove worker/control plane
### - hosts.yml에는 삭제할 노드 명시
### - remove-node.yml -e node=NODE_NAME
### - (offline) remove-node.yml -e node=NODE_NAME -e reset_nodes=false -e allow_ungraceful_removal=true
### - hosts.yml에서 삭제된 노드 제거
-------------------------------
## how to remove etcd
### - 특수한 경우가 아니라면 etcd 삭제 전에 먼저 새로운 etcd 노드를 추가하여 짝수개로 맞춰놓은 다음 삭제 과정을 거쳐야한다.(자세한 절차는 공식 repository 참고)
### - hosts.yml에는 삭제할 노드 명시
### - remove-node.yml -e node=NODE_NAME
### - (offline) remove-node.yml -e node=NODE_NAME -e reset_nodes=false -e allow_ungraceful_removal=true
### - hosts.yml에서 삭제된 노드 제거
### - cluster.yml >> 모든 노드에 설정 파일 재생성
### - 모든 control plane 노드에서 /etc/kubernetes/manifests/kube-apiserver.yaml 안의 --etcd-servers 파라미터에 삭제된 etcd 정보 제거
-------------------------------
## how to remove/recover etcd when one etcd node is down
### - hosts.yml에는 삭제할 노드 명시
### - remove-node.yml -e node=NODE_NAME
### - (offline) remove-node.yml -e node=NODE_NAME -e reset_nodes=false -e allow_ungraceful_removal=true
### - hosts.yml에서 삭제된 노드 제거 및 새로 추가될 노드 명시(etcd 노드 수는 홀수가 되어야함)
### - cluster.yml
### - 모든 control plane 노드에서 /etc/kubernetes/manifests/kube-apiserver.yaml 안의 --etcd-servers 파라미터에 새로운 etcd를 명시
-------------------------------
## how to replace first control plane node
### - hosts.yml의 [kube_control_plane] 항목에서 삭제할 control plane을 맨 아래로 배치
### - remove-node.yml -e node=NODE_NAME
### - (offline) remove-node.yml -e node=NODE_NAME -e reset_nodes=false -e allow_ungraceful_removal=true
### - 제시된 명령어(kubectl  edit cm -n kube-public cluster-info)를 이용하여 [server] 필드에 있던 삭제된 control plane 노드의 아이피를 현존하는 control plane 노드의 아이피로 변경
### - (인증서 변경했을 경우) [certificate-authority-data] 필드로 변경
### - hosts.yml에서 삭제된 노드 제거
### - cluster.yml --limit=kube_control_plane >> 모든 노드에 설정 파일 재생성
