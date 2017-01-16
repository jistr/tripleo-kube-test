#!/bin/sh


set -euxo pipefail

SERVICES="create_mysql"

create_mysql() {
   kubectl delete statefulset mysql || true 
   kubectl delete job mysql-bootstrap || true 
   kubectl delete service mysql || true
   kubectl delete configmap mariadb-kolla-config || true
}


case "${1:-all}" in
  mysql)
    SERVICES="create_mysql"
  ;;
  *)
  ;;
esac

echo "Deleting the following services: "
echo $SERVICES

for service in $SERVICES;
do
  $service
done
