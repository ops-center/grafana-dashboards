#!/bin/bash

declare -A kind=(["connectcluster"]="ConnectCluster" ["druid"]="Druid" ["elasticsearch"]="Elasticsearch" ["kafka"]="Kafka" ["mariadb"]="MariaDB"
            ["mongodb"]="MongoDB" ["mysql"]="MySQL" ["perconaxtradb"]="PerconaXtraDB" ["pgpool"]="Pgpool" ["postgres"]="Postgres" ["proxysql"]="ProxySQL"
            ["rabbitmq"]="RabbitMQ" ["redis"]="Redis" ["singlestore"]="Singlestore" ["solr"]="Solr" ["zookeeper"]="ZooKeeper")

cd ../../

folders=$(ls)

# Convert the string variable into an array
IFS=$'\n' read -r -d '' -a folder_array <<< "$folders"

for folder in "${folder_array[@]}"; do
    if [[ -v kind["$folder"] ]]; then
        kubectl apply -f
        echo "db name: $folder"
        inside_files=$(ls "$folder")
        IFS=$'\n' read -r -d '' -a inside_files_array <<< "$inside_files"
        for file in "${inside_files_array[@]}"; do
          if [[ $file == *.json ]]; then
              echo "$file"
          fi
        done
    fi
done