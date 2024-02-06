# MongoDB Grafana Dashboards

There are three dashboards to monitor MongoDB Databases managed by KubeDB.

- KubeDB / MongoDB / Summary: Shows overall summary of a MongoDB database.
- KubeDB / MongoDB / Pod: Shows individual pod-level information.
- KubeDB / MongoDB / Database (ReplicaSet): Shows MongoDB ReplicaSets internal metrics.

Note: These dashboards are developed in **Grafana version 8.2.3**

### Dependencies

MongoDB Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by Appscode](https://byte.builders/blog/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the MongoDB Grafana dashboards.

#### 2. Install Panopticon

Install Panopticon if you haven't done it already. Like other AppsCode products, [Panopticon](https://byte.builders/blog/post/introducing-panopticon/) also need a license to run.

**If you already have a license for KubeDB or Stash, you do not need to issue a new license for Panopticon. Your existing KubeDB or Stash license will work with Panopticon.**

Now, install Panopticon using the following commands:

```bash
helm upgrade -i monitoring-operator oci://ghcr.io/appscode-charts/monitoring-operator \
  --version v0.0.4 \
  -n monitoring --create-namespace

helm upgrade -i panopticon oci://ghcr.io/appscode-charts/panopticon \
  --version v2023.10.1 \
  -n monitoring --create-namespace \
  --set-file license=/path/to/license-file.txt
```

#### 3. Add monitoring configuration in KubeDB managed MongoDB spec

To enable monitoring of a KubeDB MongoDB instance, you have to add monitoring configuration in the MongoDB CR spec like below:

```
apiVersion: kubedb.com/v1alpha2
kind: MongoDB
metadata:
  name: mg-rs
  namespace: default
spec:
  ...
  ...
  monitor:
    agent: prometheus.io/operator
    prometheus:
      serviceMonitor:
        labels:
          release: prometheus
        interval: 10s
```

If you are using mongodb exporter image `kubedb/mongodb_exporter:v0.20.4` please add the following part in the monitoring section.

```yaml
  monitor:
    agent: prometheus.io/operator
    prometheus:
      exporter:
        args:
          - --compatible-mode
```

### Using Dashboards

#### Create DB Metrics Configurations

At first, you have to create a `MetricsConfiguration` object for DB. This `MetricsConfiguration` object is used by Panopticon to generate metrics for DB instances.

Install `kubedb-metrics` charts which will create the `MetricsConfiguration` object for DB:

```bash
helm upgrade -i kubedb-metrics oci://ghcr.io/appscode-charts/kubedb-metrics \
  --version v2023.12.28 \
  -n kubedb --create-namespace
```

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `mongodb` folder of this repository. If you are using mongodb exporter image `kubedb/mongodb_exporter:v0.20.4` please use the dashboards json from `mongodb/legacy` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/mongodb/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/mongodb/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the MongoDB Grafana dashboard in your Grafana UI.

### Samples

####  KubeDB / MongoDB / Summary

![KubeDB / MongoDB / Summary](/mongodb/images/kubedb-mongodb-summary.png)

#### KubeDB / MongoDB / Database (ReplicaSet)

![KubeDB / MongoDB / Database (ReplicaSet)](/mongodb/images/kubedb-mongodb-database-replset.png)

#### KubeDB / MongoDB / Pod

![KubeDB / MongoDB / Pod](/mongodb/images/kubedb-mongodb-pod.png)
