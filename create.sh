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
  kubectl create -f services/nova/compute-deployment.yaml

  kubectl create -f services/nova/keystone-job.yaml
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
  nova)
    SERVICES="create_nova"
  ;;
  rabbitmq)
    SERVICES="create_rabbitmq"
  ;;
  all)
    SERVICES="create_mariadb create_rabbitmq create_keystone create_glance create_nova"
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
