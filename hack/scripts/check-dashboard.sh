#!/bin/bash
#set -eou pipefail
DB=$1
allDbs=("ConnectCluster" "Druid" "Elasticsearch" "Kafka" "MariaDB" "MongoDB" "MySQL" "PerconaXtraDB" "Pgpool" "Postgres" "ProxySQL" "RabbitMQ" "Redis" "Singlestore" "Solr" "ZooKeeper")
kubectl create ns demo
if [ $(DB)=="all" ]; then
    kubectl apply -f https://raw.githubusercontent.com/kubedb/samples/old-dbs/mongodb/shard/mongodb.yaml
    kubectl wait --for=jsonpath='{.status.phase}'=Ready MongoDB mongodb -n demo --timeout=10m
    kubectl-dba monitor dashboard mongodb mongodb -n demo mongodb-summary-dashboard --prom-svc-name=prometheus-kube-prometheus-prometheus --prom-svc-namespace=monitoring --prom-svc-port=9090
fi