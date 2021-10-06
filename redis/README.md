# Redis Grafana Dashboards

There are three dashboards to monitor Redis Databases managed by KubeDB.

- KubeDB / Redis / Summary: Shows overall summary of an Redis instance.
- KubeDB / Redis / Pods: Shows individual pod-level information.
- KubeDB / Redis / Shards: shows Redis Shard Cluster internal metrics such as shard slots, shards nodes, cluster masters, etc.

Note: These dashboards are developed in **Grafana version 7.5.5**

### Dependencies

Redis Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by Appscode](https://blog.byte.builders/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Redis Grafana dashboards.

#### 2. Install Panopticon

Install Panopticon if you haven't done it already. Like other AppsCode products, [Panopticon](https://blog.byte.builders/post/introducing-panopticon/) also need a license to run. You can grab a 30 days trial license for Panopticon from [here](https://license-issuer.appscode.com/?p=panopticon-enterprise).

**If you already have an enterprise license for KubeDB or Stash, you do not need to issue a new license for Panopticon. Your existing KubeDB or Stash license will work with Panopticon.**

Now, install Panopticon using the following commands:

```bash
$ helm repo add appscode https://charts.appscode.com/stable/
$ helm repo update

$ helm install panopticon appscode/panopticon -n kubeops \
    --create-namespace \
    --set monitoring.enabled=true \
    --set monitoring.agent=prometheus.io/operator \
    --set monitoring.serviceMonitor.labels.release=<helm-release-name-of-kube-prometheus-stack> \
    --set-file license=/path/to/license-file.txt
```

#### 3. Add monitoring configuration in KubeDB managed Redis spec

To enable monitoring of a KubeDB Redis instance, you have to add monitoring configuration in the Redis CR spec like below:

```
apiVersion: kubedb.com/v1alpha2
kind: Redis
metadata:
  name: sample-rd
  namespace: demo
spec:
  ...
  ...
  monitor:
    agent: prometheus.io/operator
    prometheus:
      serviceMonitor:
        labels:
          release: <helm-release-name-of-kube-prometheus-stack>
        interval: 10s
```

### Using Dashboards

#### Create Redis Metrics Configurations

At first, you have to create a `MetricsConfiguration` object for Redis CR. This `MetricsConfiguration` object is used by Panopticon to generate metrics for the Redis instances.

Run the below command to create the `MetricsConfiguration` object:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubedb/installer/master/charts/kubedb-metrics/templates/metricsconfig-kubedb-com-redis.yaml
```

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `redis` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/redis/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/redis/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the Redis Grafana dashboard in your Grafana UI.

### Samples

####  KubeDB / Redis / Summary

![KubeDB / Redis / Summary](/redis/images/kubedb-redis-summary.png)

#### KubeDB / Redis / Database

![KubeDB / Redis / Shard](/redis/images/kubedb-redis-shard.png)

#### KubeDB / Redis / Pod

![KubeDB / Redis / Pod](/redis/images/kubedb-redis-pod.png)