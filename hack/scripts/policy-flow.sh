set -e

helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper/gatekeeper --name-template=gatekeeper --namespace gatekeeper-system --create-namespace --set replicas=1 --set constraintViolationsLimit=100 --wait

helm upgrade -i kube-ui-server appscode/kube-ui-server -n kubeops --create-namespace --version=v2024.5.17 --wait

kubectl apply -f ./hack/yamls/policy/constraint-template.yaml
sleep 5
kubectl apply -f ./hack/yamls/policy/constraint.yaml

