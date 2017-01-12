#!/bin/bash

set -euxo pipefail

sudo yum -y install nfs-utils
sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo setsebool -P nfs_export_all_rw 1

sudo truncate -s 0 /etc/exports.d/kubernetes-pv.exports
for EXPORT_NUM in $(seq 0 9); do
    sudo mkdir -p /export/kubernetes-pv-$EXPORT_NUM
    if ! grep /export/kubernetes-pv-$EXPORT_NUM /etc/exports; then
        echo "/export/kubernetes-pv-$EXPORT_NUM *(rw,sync,all_squash)" | sudo tee -a /etc/exports.d/kubernetes-pv.exports
    fi
done

sudo chown nfsnobody:nfsnobody /export/kubernetes-pv
sudo exportfs -rav
