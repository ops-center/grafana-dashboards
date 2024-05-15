set -e

helm repo add minio https://operator.min.io/
helm upgrade --install --namespace "minio-operator" --create-namespace "stash-minio-operator" minio/operator --set operator.replicaCount=1 --wait
helm upgrade --install --namespace "demo" --create-namespace stash-minio minio/tenant \
  --set tenant.pools[0].servers=1 \
  --set tenant.pools[0].volumesPerServer=1 \
  --set tenant.pools[0].size=1Gi \
  --set tenant.certificate.requestAutoCert=false \
  --set tenant.pools[0].name="default" \
  --set tenant.buckets[0].name="stash" \
  --wait

echo -n 'changeit' > RESTIC_PASSWORD
echo -n 'minio' > AWS_ACCESS_KEY_ID
echo -n 'minio123' > AWS_SECRET_ACCESS_KEY
kubectl create secret generic -n demo minio-secret \
  --from-file=./RESTIC_PASSWORD \
  --from-file=./AWS_ACCESS_KEY_ID \
  --from-file=./AWS_SECRET_ACCESS_KEY

helm install stash oci://ghcr.io/appscode-charts/stash \
  --version v2024.4.8 \
  --namespace stash --create-namespace \
  --set features.enterprise=true \
  --set stash-enterprise.monitoring.agent=prometheus.io/operator \
  --set stash-enterprise.monitoring.backup=true \
  --set stash-enterprise.monitoring.operator=true \
  --set stash-enterprise.monitoring.serviceMonitor.labels.release=prometheus \
  --set-file global.license=/tmp/license.txt \
  --wait --burst-limit=10000

curl -o kubectl-stash.tar.gz -fsSL https://github.com/stashed/cli/releases/download/v0.34.0/kubectl-stash-linux-amd64.tar.gz \
  && tar zxvf kubectl-stash.tar.gz \
  && chmod +x kubectl-stash-linux-amd64 \
  && sudo mv kubectl-stash-linux-amd64 /usr/local/bin/kubectl-stash \
  && rm kubectl-stash.tar.gz LICENSE.md

kubectl apply -f ./hack/yamls/stash/repository.yaml
sleep 10

kubectl apply -f ../samples/mongodb/monitoring/mongodb_standalone.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Ready MongoDB mongodb-standalone -n demo --timeout=10m

kubectl apply -f ./hack/yamls/stash/backupconfiguration.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Ready BackupConfiguration mg-st-backup -n demo --timeout=10m

kubectl-stash trigger mg-st-backup -n demo

retries=0
while true; do
  backupsession_count=$(kubectl get backupsession -n demo -l "stash.appscode.com/invoker-name=mg-st-backup" | wc -l)
  if [ $backupsession_count -ge 0 ]; then
    break
  elif [ $retries -ge 5 ]; then
      echo "backupsession not creating for backupconfiguration 'mg-st-backup'"
      exit 1
  fi
  retries=$((retries + 1))
  sleep 5
done


sleep 10s
kubectl apply -f ./hack/yamls/stash/restoresession.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded RestoreSession mg-st-restore -n demo --timeout=10m
