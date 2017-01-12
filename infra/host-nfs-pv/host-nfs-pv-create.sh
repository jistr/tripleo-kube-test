#!/bin/bash

set -euxo pipefail

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
KUBECTL_ACTION=${KUBECTL_ACTION:-create}

for EXPORT_NUM in $(seq 0 9); do
    kubectl "$KUBECTL_ACTION" -f <(sed -e "s|__EXPORT_NUM__|$EXPORT_NUM|" "$DIR/host-nfs-pv.yml.template")
done
