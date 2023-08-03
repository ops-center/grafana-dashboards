# MySQL Grafana Dashboards

There are four dashboards to monitor MySQL Databases managed by KubeDB.

- KubeDB / MySQL / Summary: Shows overall summary of an MySQL instance.
- KubeDB / MySQL / Pod: Shows individual pod-level information.
- KubeDB / MySQL / Database: shows MySQL internal metrics for an instance.
- KubeDB / MySQL / Group Replication: shows MySQL group replication metrics.

Note: These dashboards are developed in **Grafana version 7.5.5**

### Dependencies

MySQL Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by Appscode](https://byte.builders/blog/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the MySQL Grafana dashboards.

#### 2. Install Panopticon

Install Panopticon if you haven't done it already. Like other AppsCode products, [Panopticon](https://byte.builders/blog/post/introducing-panopticon/) also need a license to run.

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

#### 3. Add monitoring configuration in KubeDB managed MySQL spec

To enable monitoring of a KubeDB MySQL instance, you have to add monitoring configuration in the MySQL CR spec like below:

```
apiVersion: kubedb.com/v1alpha2
kind: MySQL
metadata:
  name: sample-mysql
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

#### Create DB Metrics Configurations

At first, you have to create a `MetricsConfiguration` object for DB. This `MetricsConfiguration` object is used by Panopticon to generate metrics for DB instances.

Install `kubedb-metrics` charts which will create the `MetricsConfiguration` object for DB:

```bash
$ helm repo add appscode https://charts.appscode.com/stable/
$ helm repo update
$ helm search repo appscode/kubedb-metrics --version=v2022.10.18
$ helm upgrade -i kubedb-metrics appscode/kubedb-metrics -n kubedb --create-namespace --version=v2022.10.18
```

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `mysql` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/mysql/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/mysql/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the MySQL Grafana dashboard in your Grafana UI.

### Samples

####  KubeDB / MySQL / Summary

![KubeDB / MySQL / Summary](/mysql/images/kubedb-mysql-summary.png)

#### KubeDB / MySQL / Database

![KubeDB / MySQL / Database](/mysql/images/kubedb-mysql-database.png)

#### KubeDB / MySQL / Pod

![KubeDB / MySQL / Pod](/mysql/images/kubedb-mysql-pod.png)

#### KubeDB / MySQL / Group-Replication

![KubeDB / MySQL / Pod](/mysql/images/kubedb-mysql-group.png)