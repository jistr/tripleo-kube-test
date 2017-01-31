#!/bin/sh

set -euo pipefail

# QUERY_TEMPLATE="{{range .items -}}
# {{.metadata.name}} {{range $k, $v := .metadata.labels}}{{$k}}{{end}}
# {{end}}"
# kubectl get nodes -o go-template --template "$QUERY_TEMPLATE"
NODE_LABELS=$(kubectl get nodes --no-headers --show-labels | awk '{ print $1 " " $4; }')
echo -e "$NODE_LABELS"
echo

REQUIRED_LABELS=(
    "tripleo/role-compute=true"
    "tripleo/role-generic=true"
    "tripleo/role-networker=true"
)

for LABEL in "${REQUIRED_LABELS[@]}"; do
    if ! grep "$LABEL" <<<"$NODE_LABELS" > /dev/null; then
        echo "WARNING: Did not find a node labeled $LABEL."
        echo "         run 'kubectl label node NODE_NAME $LABEL'"
    fi
done
