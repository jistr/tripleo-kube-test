#!/bin/bash

set -euxo pipefail

sudo yum -y install nfs-utils
sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo setsebool -P nfs_export_all_rw 1

sudo mkdir -p /export/kubernetes-pv
if ! grep /export/kubernetes-pv /etc/exports; then
    echo "/export/kubernetes-pv *(rw,sync,all_squash)" | sudo tee -a /etc/exports
fi

sudo chown nfsnobody:nfsnobody /export/kubernetes-pv
sudo exportfs -rav
