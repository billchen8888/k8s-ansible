# I neEd to modify the liyongjian's process a little bit to fit the AWS environment

# 1) dsiable SELINU on this central box

setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# 2) install ansible
yum install -y ansible

# 3) edit the group_vars/all  LB info
controlbox=`cat USERDATA| sed 's/^[ 	]*//;s/[ 	]*$//;/^$/d' |grep -v ^#| head -1|awk '{print $1}'`
if [ "$controlbox" = "" ];then
   echo "no appripoate data found in USERDATA"
   exit 1
fi


# 
sed -i "s/10.10.10.127/$controlbox/" group_vars/all

# 4) prepare the /etc/hosts
echo "$controlbox  centos7-nginx lb.5179.top inner-lb.5179.top ng.5179.top ng-inner.5179.top" >> /etc/hosts

nu_ip=`cat USERDATA|sed 's/^[ 	]*//;s/[ 	]*$//;/^$/d'|grep -v ^#| sed 1d |awk '{print $1}' |wc -l`
clusips=`cat USERDATA|sed 's/^[ 	]*//;s/[ 	]*$//;/^$/d'|grep -v ^#| sed 1d |awk '{print $1}'`
if [ $nu_ip -lt 4 ]; then
   echo we need at least 4 IPs for the k8s cluster
fi

i=0
for ip in $clusips
do
    clusterip_array[$i]=$ip
    ascii=$((97+$i))   # 97 is the character "a"
    current_char=$(printf "\\$(printf '%03o' $ascii)")
    echo $ip  centos7-$current_char  >> /etc/hosts
    i=$(($i+1))
    if [ $i -ge $nu_ip ]; then
       break
    fi
done

# 5) prepare inventory/hosts
echo "[masters]" > inventory/hosts
echo "${clusterip_array[0]}" >> inventory/hosts
echo "${clusterip_array[1]}" >> inventory/hosts
echo "${clusterip_array[2]}" >> inventory/hosts
echo >> inventory/hosts

echo "[etcd]" >> inventory/hosts
echo "${clusterip_array[0]} NODE_NAME=etcd01" >> inventory/hosts
echo "${clusterip_array[1]} NODE_NAME=etcd02" >> inventory/hosts
echo "${clusterip_array[2]} NODE_NAME=etcd03" >> inventory/hosts
echo >> inventory/hosts

echo "[nodes]" >> inventory/hosts
for ip in ${clusterip_array[@]}
do
  echo "$ip" >> inventory/hosts
done
echo >> inventory/hosts

echo "[k8s]" >> inventory/hosts
echo "${clusterip_array[0]}" >> inventory/hosts
echo "${clusterip_array[1]}" >> inventory/hosts
echo "${clusterip_array[2]}" >> inventory/hosts
echo >> inventory/hosts

echo "[local]" >>  inventory/hosts
echo "127.0.0.1" >>  inventory/hosts
echo >> inventory/hosts

echo "[lb]" >>  inventory/hosts
echo "$controlbox" >>  inventory/hosts

# set the passwd less ssh
chmod 600 ~/.ssh/id_rsa
for ip in ${clusterip_array[@]} $controlbox
do
   echo  ====================== $ip =================================
   ssh -o StrictHostKeyChecking=no centos@$ip "sudo  sed -i 's/^.\{,155\}//' /root/.ssh/authorized_keys"
   if [ $? -ne 0 ]; then
     echo "!!!!!!!! ERROR !!!!!! Looks like the private key doesn't work. Please get teh private key first"
   else
     echo "passwdless ssh should work for root@$ip now"
   fi
done

# run ssh command to 127.0.0.1 to accept the fingerprint
echo ssh command to 127.0.0.1 hostname
ssh -o StrictHostKeyChecking=no 127.0.0.1 hostname
