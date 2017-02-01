#!/bin/sh

set -eu

# QUERY_TEMPLATE="{{range .items -}}
# {{.metadata.name}} {{range $k, $v := .metadata.labels}}{{$k}}{{end}}
# {{end}}"
# kubectl get nodes -o go-template --template "$QUERY_TEMPLATE"
NODE_LABELS=$(kubectl get nodes --no-headers --show-labels | awk '{ print $1 " " $4; }')
echo -e "$NODE_LABELS"
echo

L2_LABEL="tripleo/service-l2-agent=true"
L2_LABEL_REMOVE="tripleo/service-l2-agent-"
REQUIRED_LABELS=(
    "tripleo/role-compute=true"
    "tripleo/role-generic=true"
    "tripleo/role-networker=true"
)
L2_REQUIRED_LABELS_GREP=(
    "\(tripleo/role-compute=true\)\|\(tripleo/role-networker=true\)"
)

for LABEL in "${REQUIRED_LABELS[@]}"; do
    if ! grep "$LABEL" <<<"$NODE_LABELS" > /dev/null; then
        echo "WARNING: Did not find a node labeled $LABEL."
        echo "         run 'kubectl label node NODE_NAME $LABEL'"
    fi
done


MISSING_L2=$(grep "$L2_REQUIRED_LABELS_GREP" <<<"$NODE_LABELS" | grep -v "$L2_LABEL" | awk '{ print $1; }')
if [ -n "$MISSING_L2" ]; then
    echo "WARNING: Missing $L2_LABEL on nodes: $(tr '\n' ' ' <<<$MISSING_L2)"
    for NODE in $MISSING_L2; do
        CMD="kubectl label node $NODE $L2_LABEL"
        echo "Press C-c to exit, or anything to run '$CMD'"
        read
        $CMD
    done
fi

EXTRA_L2=$(grep "$L2_LABEL" <<<"$NODE_LABELS" | grep -v "$L2_REQUIRED_LABELS_GREP" | awk '{ print $1; }')
if [ -n "$EXTRA_L2" ]; then
    echo "WARNING: Superfluous $L2_LABEL on nodes: $(tr '\n' ' ' <<<$EXTRA_L2)"
    for NODE in $EXTRA_L2; do
        CMD="kubectl label node $NODE $L2_LABEL_REMOVE"
        echo "Press C-c to exit, or anything to run '$CMD'"
        read
        $CMD
    done
fi
