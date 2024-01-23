#!/bin/bash

#############################################
# YOU SHOULD ONLY NEED TO EDIT THIS SECTION #
#############################################
# Set the IP addresses of master1
master1=172.16.200.61

# Set the IP addresses of your Longhorn nodes
longhorn1=172.16.200.81
longhorn2=172.16.200.82
longhorn3=172.16.200.83

# User of remote machines
user=michelix

# Interface used on remotes
interface=eth0

# Set the virtual IP address (VIP)
vip=172.16.200.200

# Array of longhorn nodes
storage=($longhorn1 $longhorn2 $longhorn3)

#ssh certificate name variable
certName=id_ansible

#############################################
#            DO NOT EDIT BELOW              #
#############################################
# For testing purposes - in case time is wrong due to VM snapshots
#sudo timedatectl set-ntp off
#sudo timedatectl set-ntp on

# add ssh keys for all nodes
#for node in "${storage[@]}"; do
#  ssh-copy-id $user@$node
#done

# add open-iscsi - needed for Debian and non-cloud Ubuntu
if ! command -v sudo service open-iscsi status &> /dev/null
then
    echo -e " \033[31;5mOpen-ISCSI not found, installing\033[0m"
    sudo apt install open-iscsi
else
    echo -e " \033[32;5mOpen-ISCSI already installed\033[0m"
fi

# Step 1: Add new longhorn nodes to cluster (note: label added)
for newnode in "${storage[@]}"; do
  k3sup join \
    --ip $newnode \
    --user $user \
    --sudo \
    --k3s-channel stable \
    --server-ip $master1 \
    --k3s-extra-args "--node-label \"longhorn=true\"" \
    --ssh-key $HOME/.ssh/$certName
  echo -e " \033[32;5mAgent node joined successfully!\033[0m"
done

# Step 2: Install Longhorn (using modified Official to pin to Longhorn Nodes)
kubectl apply -f https://raw.githubusercontent.com/michelix/k3s/main/longhorn.yaml
kubectl get pods \
--namespace longhorn-system \
--watch

# Step 3: Print out confirmation

kubectl get nodes
kubectl get svc -n longhorn-system

echo -e " \033[32;5mHappy Kubing! Access Longhorn through Rancher UI\033[0m"
