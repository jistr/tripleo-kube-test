#!/bin/bash

# to create run: ./infra/host-nfs-pv/host-nfs-pv-create.sh
# to delete run: KUBECTL_ACTION=delete ./infra/host-nfs-pv/host-nfs-pv-create.sh

set -euxo pipefail

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
KUBECTL_ACTION=${KUBECTL_ACTION:-create}

for EXPORT_NUM in $(seq 0 9); do
    kubectl "$KUBECTL_ACTION" -f <(sed -e "s|__EXPORT_NUM__|$EXPORT_NUM|" "$DIR/host-nfs-pv.yml.template")
done
