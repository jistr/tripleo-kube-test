#!/bin/sh


set -euxo pipefail

SERVICES="delete_glance delete_keystone delete_mysql delete_rabbitmq delete_all_pvc"

delete_glance() {
  kubectl delete deployment glance-api || true
  kubectl delete job glance-api-createdb || true
  kubectl delete job glance-api-bootstrap || true
  kubectl delete service glance-api || true
  kubectl delete configmap glance-api-kolla-config || true
}

delete_keystone() {
  kubectl delete job keystone-db-create || true
  kubectl delete job keystone-db-sync || true
  kubectl delete job keystone-fernet-bootstrap || true
  kubectl delete job keystone-bootstrap || true
  kubectl delete deployment keystone || true
  kubectl delete service keystone || true
  kubectl delete service keystone-admin || true
  kubectl delete configmap keystone-kolla-config || true
  kubectl delete pvc keystone-fernet || true
  kubectl exec -ti mysql-0 -- mysql -h mysql -u root --password=weakpassword -e "drop database keystone;" || true
}

delete_mysql() {
  kubectl delete statefulset mysql || true
  kubectl delete job mysql-bootstrap || true
  kubectl delete service mysql || true
  kubectl delete configmap mariadb-kolla-config || true
}

delete_rabbitmq() {
  kubectl delete statefulset rabbitmq || true
  kubectl delete service rabbitmq || true
  kubectl delete configmap rabbitmq-kolla-config || true
}

delete_all_pvc() {
  kubectl get pvc -o name | xargs -n1 kubectl delete || true
}

case "${1:-all}" in
  glance)
    SERVICES="delete_glance"
  ;;
  keystone)
    SERVICES="delete_keystone"
  ;;
  mysql)
    SERVICES="delete_mysql"
  ;;
  rabbitmq)
    SERVICES="delete_rabbitmq"
  ;;
  all_pvc)
    SERVICES="delete_all_pvc"
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
