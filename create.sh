#!/bin/sh


set -euxo pipefail

SERVICES="create_mysql create_rabbitmq create_glance create_keystone"

wait_for_job() {
    SLEEP=5
    JOB_NAME="$1"
    TIMEOUT="${2:-120}"  # approximate

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

create_mysql() {
  kubectl create -f services/mysql/configmap.yaml
  kubectl create -f services/mysql/service.yaml
  kubectl create -f services/mysql/statefulset.yaml -f services/mysql/bootstrap-job.yaml
  wait_for_job mysql-bootstrap
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
  kubectl create -f services/glance/deployment.yaml #-f services/glance/bootstrap-job.yaml
}

create_keystone() {
  kubectl create -f services/keystone/fernet-pvc.yaml
  kubectl create -f services/keystone/configmap.yaml
  kubectl create -f services/keystone/service.yaml
  kubectl create -f services/keystone/service-admin.yaml
  kubectl create -f services/keystone/db-create-job.yaml
  wait_for_job keystone-db-create
  kubectl create -f services/keystone/db-sync-job.yaml
  kubectl create -f services/keystone/fernet-bootstrap-job.yaml
  wait_for_job keystone-db-sync
  wait_for_job keystone-fernet-bootstrap
  kubectl create -f services/keystone/bootstrap-job.yaml
  wait_for_job keystone-bootstrap
  kubectl create -f services/keystone/deployment.yaml
}

case "${1:-all}" in
  glance)
    SERVICES="create_glance"
  ;;
  keystone)
    SERVICES="create_keystone"
  ;;
  mysql)
    SERVICES="create_mysql"
  ;;
  rabbitmq)
    SERVICES="create_rabbitmq"
  ;;
  *)
  ;;
esac

echo "Registering the following services: "
echo $SERVICES

for service in $SERVICES;
do
  $service
done
