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
- [Panopticon by Appscode](https://blog.byte.builders/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the MongoDB Grafana dashboards.

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

#### Create MongoDB Metrics Configurations

At first, you have to create a `MetricsConfiguration` object for MongoDB CR. This `MetricsConfiguration` object is used by Panopticon to generate metrics for the MongoDB databases.

Run the below command to create the `MetricsConfiguration` object:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubedb/installer/master/charts/kubedb-metrics/templates/metricsconfig-kubedb-com-mongodb.yaml
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
