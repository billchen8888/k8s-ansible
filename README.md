# k8s-ansible

adjust my setting to match your environment `group_vars/all` 和`inventory/hosts`文件

## Version used

K8S_SERVER_VER=1.18.3

ETCD_VER=3.4.9

FLANNEL_VER=0.12.0

CNI_PLUGIN_VER=0.8.6

CALICO_VER=3.15.0

DOCKER_VER=19.03.10  

## Subnet Info

pod subnet：10.244.0.0/16

service subnet：10.96.0.0/12

kubernetes internal IP：10.96.0.1

coredns address： 10.96.0.10


## machines/instances

| machine       | IP           |  role and component      |                         k8s realted components               |
| ------------- | ------------ | :----------------------: | :----------------------------------------------------------: |
| centos7-nginx | 10.10.10.127 |  nginx layer4 proxy      |                        nginx  ansible                             |
| centos7-a     | 10.10.10.128 | master,node,etcd,flannel | kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy |
| centos7-b     | 10.10.10.129 | master,node,etcd,flannel | kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy |
| centos7-c     | 10.10.10.130 | master,node,etcd,flannel | kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy |
| centos7-d     | 10.10.10.131 |       node,flannel       |                      kubelet kube-proxy                      |
| centos7-e     | 10.10.10.132 |       node,flannel       |                      kubelet kube-proxy                      |



## preparation
execute  `download_binary.sh` script to download
```bash
bash download_binary.sh
```
If you cannot run download_binary, then go to  `/opt/pkg/`
```bash
wget https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGIN_VER}/cni-plugins-linux-amd64-v${CNI_PLUGIN_VER}.tgz && \
wget https://github.com/coreos/flannel/releases/download/v${FLANNEL_VER}/flannel-v${FLANNEL_VER}-linux-amd64.tar.gz && \
wget https://dl.k8s.io/v${K8S_SERVER_VER}/kubernetes-server-linux-amd64.tar.gz && \
wget https://github.com/etcd-io/etcd/releases/download/v${ETCD_VER}/etcd-v${ETCD_VER}-linux-amd64.tar.gz && \
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 &&\
wget https://github.com/projectcalico/calicoctl/releases/download/v{CALICOCTL_VER}/calicoctl
```
then run `tools/move_pkg.sh`  to unzip/extract
```bash
bash tools/move_pkg.sh
```

## modify the hosts file on the control box

```bash
[root@centos7-nginx k8s-ansible]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.10.10.127 centos7-nginx lb.5179.top inner-lb.5179.top ng.5179.top ng-inner.5179.top
10.10.10.128 centos7-a
10.10.10.129 centos7-b
10.10.10.130 centos7-c
10.10.10.131 centos7-d
10.10.10.132 centos7-e
```

## execute
```bash
ansible-playbook -i inventory/hosts  site.yml
```

After the execution, we can see
```bash
[root@centos7-nginx k8s-ansible]# kubectl get nodes
NAME           STATUS   ROLES    AGE     VERSION
10.10.10.128   Ready    master   7m48s   v1.18.3
10.10.10.129   Ready    master   7m49s   v1.18.3
10.10.10.130   Ready    master   7m49s   v1.18.3
10.10.10.131   Ready    <none>   7m49s   v1.18.3
10.10.10.132   Ready    <none>   7m49s   v1.18.3

[root@centos7-nginx k8s-ansible]# kubectl describe nodes 10.10.10.128 |grep -C 3 Taints
Annotations:        node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Thu, 25 Jun 2020 17:38:09 +0800
Taints:             node-role.kubernetes.io/master:NoSchedule
Unschedulable:      false
Lease:
  HolderIdentity:  10.10.10.128
```

## add new nodes

modify `invertory/hosts`的`[new-nodes]`
then run 
```bash
ansible-playbook -i inventory/hosts new_nodes.yml
```
## test cluster
```
[root@centos7-nginx k8s-ansible]# kubectl apply -f tests/myapp.yaml
```
basic validation
```bash
[root@centos7-nginx k8s-ansible]# kubectl exec -it busybox -- sh
/ #
/ # nslookup kubernetes
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
/ # nslookup myapp
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      myapp
Address 1: 10.102.233.224 myapp.default.svc.cluster.local
/ #
/ # curl myapp/hostname.html
myapp-5cbd66595b-p6zlp
```

## clean

```bash
bash ./tools/clean.sh
```
