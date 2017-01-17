#!/bin/sh


set -euxo pipefail

SERVICES="create_mysql create_rabbitmq create_glance"  

create_mysql() {
  kubectl create -f services/mysql/configmap.yaml
  kubectl create -f services/mysql/service.yaml
  kubectl create -f services/mysql/statefulset.yaml -f services/mysql/bootstrap-job.yaml
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

case "${1:-all}" in
  glance)
    SERVICES="create_glance"
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
