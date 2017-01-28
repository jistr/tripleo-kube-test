#!/bin/sh


set -euxo pipefail

delete_glance() {
  kubectl delete deployment glance-api || true
  kubectl delete job glance-db-sync || true
  kubectl delete job glance-api-keystone || true
  kubectl delete service glance-api || true
  kubectl delete configmap glance-api-kolla-config || true
  kubectl delete pvc glance-api-pvc || true
  kubectl exec -ti mariadb-0 -- mysql -h mariadb -u root --password=weakpassword -e "drop database glance;" || true
}

delete_keystone() {
  kubectl delete job keystone-db-sync || true
  kubectl delete job keystone-fernet-bootstrap || true
  kubectl delete job keystone-bootstrap || true
  kubectl delete deployment keystone || true
  kubectl delete service keystone || true
  kubectl delete service keystone-admin || true
  kubectl delete configmap keystone-kolla-config || true
  kubectl delete pvc keystone-fernet || true
  kubectl exec -ti mariadb-0 -- mysql -h mariadb -u root --password=weakpassword -e "drop database keystone;" || true
}

delete_mariadb() {
  kubectl delete statefulset mariadb || true
  kubectl delete service mariadb || true
  kubectl delete configmap mariadb-kolla-config || true
}

delete_nova() {
  kubectl delete job nova-db-sync || true
  kubectl delete job nova-api-keystone || true

  # compute 
  kubectl delete deployment nova-compute || true
  kubectl delete configmap libvirt-kolla-config || true
  kubectl delete configmap nova-compute-kolla-config || true

  # scheduler
  kubectl delete deployment nova-scheduler || true
  kubectl delete configmap nova-scheduler-kolla-config || true

  # scheduler
  kubectl delete deployment nova-conductor || true
  kubectl delete configmap nova-conductor-kolla-config || true

  # api
  kubectl delete deployment nova-api || true
  kubectl delete service nova-api || true
  kubectl delete configmap nova-api-kolla-config || true

  kubectl exec -ti mariadb-0 -- mysql -h mariadb -u root --password=weakpassword -e "drop database nova;" || true
  kubectl exec -ti mariadb-0 -- mysql -h mariadb -u root --password=weakpassword -e "drop database nova_api;" || true
}

delete_rabbitmq() {
  kubectl delete statefulset rabbitmq || true
  kubectl delete service rabbitmq || true
  kubectl delete configmap rabbitmq-kolla-config || true
}

delete_all_pvc() {
  kubectl get pvc -o name | xargs -n1 kubectl delete || true
}

delete_neutron() {
  kubectl delete job neutron-db-sync || true
  kubectl delete job neutron-api-keystone || true
  
  # api
  kubectl delete deployment neutron-api || true
  kubectl delete service neutron-api || true
  kubectl delete configmap neutron-api-kolla-config || true
  
  kubectl exec -ti mariadb-0 -- mysql -h mariadb -u root --password=weakpassword -e "drop database neutron;" || true
}

case "${1:-all}" in
  glance)
    SERVICES="delete_glance"
  ;;
  keystone)
    SERVICES="delete_keystone"
  ;;
  mariadb)
    SERVICES="delete_mariadb"
  ;;
  neutron)
    SERVICES="delete_neutron"
  ;;
  nova)
    SERVICES="delete_nova"
  ;;
  rabbitmq)
    SERVICES="delete_rabbitmq"
  ;;
  all_pvc)
    SERVICES="delete_all_pvc"
  ;;
  all)
    SERVICES="delete_nova delete_neutron delete_glance delete_keystone delete_mariadb delete_rabbitmq delete_all_pvc"
  ;;
  *)
      echo "Unrecognized service $1."
      exit 1
  ;;
esac

echo "Deleting the following services: "
echo $SERVICES

for service in $SERVICES;
do
  $service
done
