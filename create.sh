#!/bin/sh


set -euxo pipefail

SERVICES="create_mysql"

create_mysql() {
   kubectl create -f services/mysql/configmap.yaml
   kubectl create -f services/mysql/service.yaml
   kubectl create -f services/mysql/statefulset.yaml -f services/mysql/bootstrap-job.yml
}


case "${1:-all}" in
  mysql)
    SERVICES="create_mysql"
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
