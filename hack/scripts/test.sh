#!/bin/bash

set -e

declare -A kind=(["connectcluster"]="ConnectCluster" ["druid"]="Druid" ["elasticsearch"]="Elasticsearch" ["kafka"]="Kafka" ["mariadb"]="MariaDB"
            ["mongodb"]="MongoDB" ["mysql"]="MySQL" ["perconaxtradb"]="PerconaXtraDB" ["pgpool"]="Pgpool" ["postgres"]="Postgres" ["proxysql"]="ProxySQL"
            ["rabbitmq"]="RabbitMQ" ["redis"]="Redis" ["singlestore"]="Singlestore" ["solr"]="Solr" ["zookeeper"]="ZooKeeper")

#kubectl apply -f safklkasg.yaml
# Capture the output of ls into an array
readarray -t files < <(ls)

# Displaying elements of the array
for file in "${files[@]}"; do
    echo "$file"
done
#cd ../../
#kubectl create ns demo
#
#folders=$(ls)
##path=/home/sayed/go/src/kubedb.dev/samples/kafka/
##kubectl apply -f $path
#
## Convert the string variable into an array
#IFS=$'\n' read -r -d '' -a folder_array <<< "$folders"
#
#for folder in "${folder_array[@]}"; do
#  if [[ -v kind["$folder"] ]] && [[ "$folder" == "mongodb" ]]; then
#    kubectl apply -f
#    echo "db name: $folder"
#    inside_files=$(ls "$folder")
#    path=../samples/"$folder"/monitoring/
#    kubectl apply -f $path
#    kubectl wait --for=jsonpath='{.status.phase}'=Ready ${kind[$folder]} $folder -n demo --timeout=10m
#    IFS=$'\n' read -r -d '' -a inside_files_array <<< "$inside_files"
#    for file in "${inside_files_array[@]}"; do
#      if [[ $file == *.json ]]; then
#        dashboard_name="${file::-5}"
#        kubectl-dba monitor dashboard $folder $folder -n demo dashboard_name --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090
#      fi
#    done
#  fi
#done