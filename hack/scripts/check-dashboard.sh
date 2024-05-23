#!/bin/bash
set -e

declare -A kind=(["connectcluster"]="ConnectCluster" ["druid"]="Druid" ["elasticsearch"]="Elasticsearch" ["kafka"]="Kafka" ["mariadb"]="MariaDB"
            ["mongodb"]="MongoDB" ["mysql"]="MySQL" ["perconaxtradb"]="PerconaXtraDB" ["pgpool"]="Pgpool" ["postgres"]="Postgres" ["proxysql"]="ProxySQL"
            ["rabbitmq"]="RabbitMQ" ["redis"]="Redis" ["singlestore"]="Singlestore" ["solr"]="Solr" ["zookeeper"]="ZooKeeper")

# export the ENVs from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# folder_array will hold all the folder names that we are going to check
readarray -t folder_array < <(ls)
IFS=',' read -r -a user_array <<< "$FOLDERS"
if [ $FOLDERS != "all" ]; then
    folder_array=("${user_array[@]}")
fi
echo "folder_array = ${folder_array}"

create_db_dependencies() {
    folder="$1"
    echo "folder=$folder"
    if [ "$folder" == "druid" ]; then
        kubectl create configmap -n demo my-init-script \
          --from-literal=init.sql="$(curl -fsSL https://raw.githubusercontent.com/kubedb/samples/old-dbs/druid/monitoring/mysql-init-script.sql)"

        helm repo add minio https://operator.min.io/
        helm upgrade --install --namespace "minio-operator" --create-namespace "minio-operator" minio/operator --set operator.replicaCount=1 --wait
        helm upgrade --install --namespace "demo" --create-namespace druid-minio minio/tenant \
          --set tenant.pools[0].servers=1 \
          --set tenant.pools[0].volumesPerServer=1 \
          --set tenant.pools[0].size=1Gi \
          --set tenant.certificate.requestAutoCert=false \
          --set tenant.pools[0].name="default" \
          --set tenant.buckets[0].name="druid" \
          --wait

        kubectl apply -f ../samples/druid/monitoring/mysql.yaml
        kubectl apply -f ../samples/druid/monitoring/zookeeper.yaml

        kubectl wait --for=jsonpath='{.status.phase}'=Ready MySQL mysql -n demo --timeout=10m
        kubectl wait --for=jsonpath='{.status.phase}'=Ready ZooKeeper zookeeper -n demo --timeout=10m
    fi

    if [ "$folder" == "pgpool" ]; then
      kubectl apply -f ../samples/pgpool/monitoring/conf.yaml
      kubectl apply -f ../samples/pgpool/monitoring/postgres.yaml
      kubectl wait --for=jsonpath='{.status.phase}'=Ready Postgres postgres -n demo --timeout=10m
    fi

    if [ "$folder" == "singlestore" ]; then
        kubectl create secret generic -n demo license-secret \
          --from-literal=username=$SINGLESTORE_LICENSE_USERNAME \
          --from-literal=password=$SINGLESTORE_LICENSE_PASSWORD
    fi

    if [ "$folder" == "solr" ]; then
        kubectl apply -f ../samples/solr/monitoring/zookeeper.yaml
        kubectl wait --for=jsonpath='{.status.phase}'=Ready ZooKeeper zookeeper -n demo --timeout=10m
    fi
}

delete_db_dependencies() {

}

check_dashboard_for_non_dbs() {
    sleep 30s # waiting for the metrics to be generated
    folder="$1"
    inside_files_array="$2"
    for file in "${inside_files_array[@]}"; do
      if [[ $file == *.json ]]; then
        dashboard_name="${file::-5}"
        echo "checking for dashboard $dashboard_name"
        url="https://raw.githubusercontent.com/appscode/grafana-dashboards/master/$folder/$file"
        $HOME/go/bin/kubectl-dba monitor dashboard -u $url -o=true --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090
      fi
    done
}


kubectl create ns demo

for folder in "${folder_array[@]}"; do
  if [[ -v kind["$folder"] ]]; then
    echo "db name: $folder"

    readarray -t inside_files_array < <(ls "$folder")

    path=../samples/"$folder"/monitoring/

    if [ "$folder" == "connectcluster" ]; then
        path=../samples/kafka/connectcluster/monitoring/
    fi

    create_db_dependencies "$folder"

    kubectl apply -f $path
    kubectl wait --for=jsonpath='{.status.phase}'=Ready ${kind[$folder]} $folder -n demo --timeout=10m

    sleep 30s
    for file in "${inside_files_array[@]}"; do
      if [[ $file == *.json ]]; then
        dashboard_name="${file::-5}"
        echo "checking for dashboard $dashboard_name"
        $HOME/go/bin/kubectl-dba monitor dashboard $folder $folder -n demo $dashboard_name --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090
      fi
    done

    kubectl delete -f $path
    delete_db_dependencies "$folder"
  elif [ "$folder" == "stash" ]; then
    echo "non db object name: $folder"
    readarray -t inside_files_array < <(ls "$folder")

    bash ./hack/scripts/stash-flow.sh
    check_dashboard_for_non_dbs "$folder" "$inside_files_array"

    kubectl delete -f ./hack/yamls/backupconfiguration.yaml
    kubectl delete -f ./hack/yamls/restoresession.yaml
    kubectl delete -f ./hack/yamls/repository.yaml
    kubectl delete -f ../samples/mongodb/monitoring/mongodb_standalone.yaml

  elif [ "$folder" == "policy" ]; then
    echo "non db object name: $folder"
    readarray -t inside_files_array < <(ls "$folder")

    bash ./hack/scripts/policy-flow.sh
    check_dashboard_for_non_dbs "$folder" "$inside_files_array"

    kubectl delete -f ./hack/yamls/policy/constraint-template.yaml
    kubectl delete -f ./hack/yamls/policy/constraint.yaml
  fi
done