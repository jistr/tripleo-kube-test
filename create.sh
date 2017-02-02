#!/bin/sh


set -euxo pipefail

wait_for_job() {
    SLEEP=5
    JOB_NAME="$1"
    TIMEOUT="${2:-180}"  # approximate

    TRY=0
    MAX_TRIES=$(( $TIMEOUT / $SLEEP ))
    while [ $TRY -lt $MAX_TRIES ]; do
        TRY=$(( $TRY + 1 ))

        if kubectl get jobs -o=jsonpath='{.items[?(@.status.succeeded)].metadata.name}' | grep "\<$JOB_NAME\>"; then
            return 0
        fi

        sleep $SLEEP
    done

    echo "Timed out."
    exit 1
}

create_mariadb() {
  kubectl create -f services/mariadb/configmap.yaml
  kubectl create -f services/mariadb/service.yaml
  kubectl create -f services/mariadb/statefulset.yaml
}

create_rabbitmq() {
  kubectl create -f services/rabbitmq/configmap.yaml
  kubectl create -f services/rabbitmq/service.yaml
  kubectl create -f services/rabbitmq/statefulset.yaml
}

create_glance() {
  kubectl create -f services/glance/pvc.yaml
  kubectl create -f services/glance/configmap.yaml
  kubectl create -f services/glance/service.yaml
  kubectl create -f services/glance/deployment.yaml
  kubectl create -f services/glance/db-sync-job.yaml
  kubectl create -f services/glance/keystone-job.yaml
}

create_keystone() {
  kubectl create -f services/keystone/configmap.yaml
  kubectl create -f services/keystone/fernet-pvc.yaml
  kubectl create -f services/keystone/fernet-bootstrap-job.yaml
  kubectl create -f services/keystone/db-sync-job.yaml
  kubectl create -f services/keystone/bootstrap-job.yaml
  kubectl create -f services/keystone/service.yaml
  kubectl create -f services/keystone/service-admin.yaml
  kubectl create -f services/keystone/deployment.yaml
}

create_nova() {
  kubectl create -f services/nova/api-configmap.yaml
  kubectl create -f services/nova/db-sync-job.yaml

  # api
  kubectl create -f services/nova/api-service.yaml
  kubectl create -f services/nova/api-deployment.yaml

  # conductor
  kubectl create -f services/nova/conductor-configmap.yaml
  kubectl create -f services/nova/conductor-deployment.yaml

  # scheduler
  kubectl create -f services/nova/scheduler-configmap.yaml
  kubectl create -f services/nova/scheduler-deployment.yaml

  # compute
  kubectl create -f services/nova/libvirt-configmap.yaml
  kubectl create -f services/nova/compute-configmap.yaml
  kubectl create -f services/nova/compute-daemonset.yaml

  kubectl create -f services/nova/keystone-job.yaml
}

create_neutron() {
  kubectl create -f services/neutron/api-configmap.yaml
  kubectl create -f services/neutron/db-sync-job.yaml

  # api
  kubectl create -f services/neutron/api-service.yaml
  kubectl create -f services/neutron/api-deployment.yaml

  # ovs-agent
  kubectl create -f services/neutron/ovs-agent-configmap.yaml
  kubectl create -f services/neutron/ovs-agent-daemonset.yaml

  kubectl create -f services/neutron/keystone-job.yaml
}

create_openvswitch() {
  kubectl create -f services/openvswitch/db-server-configmap.yaml
  kubectl create -f services/openvswitch/db-server-daemonset.yaml

  kubectl create -f services/openvswitch/vswitchd-configmap.yaml
  kubectl create -f services/openvswitch/vswitchd-daemonset.yaml
}

# currently `dnsPolicy: ClusterFirst` doesn't work with `hostNetwork:
# true`, which means pods running in hostNetwork mode cannot reach
# cluster services
# https://github.com/kubernetes/kubernetes/issues/17406
# we'll create a custom configmap to inject proper resolv.conf into
# hostNetwork pods
create_resolv_conf() {
  DNS_IP=$(kubectl get service -n kube-system kube-dns -o go-template --template '{{.spec.clusterIP}}')
  DNS_POD=$(kubectl get pod -n kube-system | grep ^kube-dns | awk '{ print $1; }')
  DOMAIN=$(kubectl get pod -n kube-system -o json $DNS_POD | grep '"--domain=' | sed -Ee 's/.*"--domain=(.*)\.".*/\1/')
  kubectl create -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: resolv-conf
data:
  resolv.conf: |
    search default.svc.$DOMAIN svc.$DOMAIN $DOMAIN
    nameserver $DNS_IP
    ndots:5
EOF
}

case "${1:-all}" in
  glance)
    SERVICES="create_glance"
  ;;
  keystone)
    SERVICES="create_keystone"
  ;;
  mariadb)
    SERVICES="create_mariadb"
  ;;
  neutron)
    SERVICES="create_neutron"
  ;;
  nova)
    SERVICES="create_nova"
  ;;
  openvswitch)
    SERVICES="create_openvswitch"
  ;;
  rabbitmq)
    SERVICES="create_rabbitmq"
  ;;
  resolv_conf)
    SERVICES="create_resolv_conf"
  ;;
  all)
    SERVICES="create_resolv_conf create_mariadb create_rabbitmq create_openvswitch create_keystone create_glance create_neutron create_nova"
  ;;
  *)
      echo "Unrecognized service $1."
      exit 1
  ;;
esac

echo "Registering the following services: "
echo $SERVICES

for service in $SERVICES;
do
  $service
done
