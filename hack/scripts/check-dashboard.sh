#!/bin/bash
#set -e

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

PROMETHEUS_SERVICE_NAMESPACE="monitoring"
PROMETHEUS_SERVICE_NAME="prometheus-kube-prometheus-prometheus"
kubectl port-forward svc/${PROMETHEUS_SERVICE_NAME} 9090:9090 -n ${PROMETHEUS_SERVICE_NAMESPACE} &
# `$!` is a special variable in bash that holds the PID of the most recently executed background command.
PORT_FORWARD_PID=$!

# Give port-forwarding some time to establish
sleep 5

create_db_dependencies() {
    folder="$1"
    echo "folder=$folder"
    if [ "$folder" == "druid" ]; then
        kubectl create configmap -n demo my-init-script \
          --from-literal=init.sql="$(curl -fsSL https://raw.githubusercontent.com/kubedb/samples/master/druid/monitoring/mysql-init-script.sql)"

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

    if [ "$folder" == "connectcluster" ]; then
        kubectl apply -f ../samples/kafka/connectcluster/monitoring/kafka.yaml
        kubectl wait --for=jsonpath='{.status.phase}'=Ready Kafka kafka -n demo --timeout=10m

        kubectl apply -f ../samples/kafka/connectcluster/monitoring/connect-cluster.yaml
        kubectl wait --for=jsonpath='{.status.phase}'=Ready ConnectCluster connectcluster -n demo --timeout=10m

        kubectl apply -f ../samples/kafka/connectcluster/monitoring/file-source.yaml
        sleep 2s
    fi
}

cleanup() {
  path="$1"
  folder="$2"
  if [ $folder == "connectcluster" ]; then
    kubectl delete -f ../samples/kafka/connectcluster/monitoring/connect-cluster.yaml
  fi
  kubectl delete -f $path
}

check_dashboard_for_non_dbs() {
    sleep 60s # waiting for the metrics to be generated
    folder="$1"
    inside_files_array="$2"
    for file in "${inside_files_array[@]}"; do
      if [[ $file == *.json ]]; then
        dashboard_name="${file::-5}"
        echo "checking for dashboard $dashboard_name"
        url="https://raw.githubusercontent.com/appscode/grafana-dashboards/master/$folder/$file"
        echo "$HOME/go/bin/kubectl-dba monitor dashboard -u $url -o=true --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090"
        $HOME/go/bin/kubectl-dba monitor dashboard -u $url -d=false --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090
      fi
    done
}

wait_for_prometheus_target() {
  target="$1"
  echo "checking if $target-stats target exist in prometheus..."
  for (( i=1; i<=600; i++ )); do
      # Curl the Prometheus API to get the targets and extract the pool information
      Targets=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | .labels.service')
      if echo "$Targets" | grep -q "$target"; then
        echo "$target target found in prometheus"
        sleep 30s
        break
      fi
      sleep 5s
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

    wait_for_prometheus_target "$folder-stats"

    for file in "${inside_files_array[@]}"; do
      if [[ $file == *.json ]]; then
        dashboard_name="${file::-5}"
        echo "checking for dashboard $dashboard_name"
        echo "$HOME/go/bin/kubectl-dba monitor dashboard $folder $folder -n demo $dashboard_name --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090 -b=workflow"
        $HOME/go/bin/kubectl-dba monitor dashboard $folder $folder -n demo $dashboard_name --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090 -b=workflow
      fi
    done
#    cleanup "$path" "$folder"

  elif [ "$folder" == "stash" ]; then
    echo "non db object name: $folder"
    readarray -t inside_files_array < <(ls "$folder")

    bash ./hack/scripts/stash-flow.sh
    wait_for_prometheus_target "stash-stash-enterprise"
    check_dashboard_for_non_dbs "$folder" "$inside_files_array"

    cleanup "./hack/yamls/stash"

  elif [ "$folder" == "policy" ]; then
    echo "non db object name: $folder"
    readarray -t inside_files_array < <(ls "$folder")

    bash ./hack/scripts/policy-flow.sh
    wait_for_prometheus_target "falco-ui-server"
    check_dashboard_for_non_dbs "$folder" "$inside_files_array"

    cleanup "./hack/yamls/policy"
  fi

done

kill $PORT_FORWARD_PID