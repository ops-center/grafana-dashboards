# Postgres Grafana Dashboards

There are three dashboards to monitor a Postgres Database managed by KubeDB.

- KubeDB / Postgres / Summary: Shows overall summary of a Postgres instance.
- KubeDB / Postgres / Pod: Shows individual database pod-level information.
- KubeDB / Postgres / Database: shows Postgres internal databases metrics.

Note: These dashboards are developed in **Grafana version 7.4.5**

### Dependencies

Postgres Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by Appscode](https://byte.builders/blog/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Postgres Grafana dashboards.

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
  -n kubeops --create-namespace \
  --set-file license=/path/to/license-file.txt
```

#### 3. Add monitoring configuration in KubeDB Postgres resource yaml

To enable monitoring of a KubeDB Postgres instance, you have to add monitoring configuration in the Postgres resource yaml spec like below:

```
apiVersion: kubedb.com/v1alpha2
kind: Postgres
metadata:
  name: sample-postgres-with-monitoring
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

Now, on your Grafana UI, import the json files of dashboards located in the `postgres` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/postgres/images/import_dashboard_1.png)

2. Upload the json file

![Upload Dashboard JSON](/postgres/images/import_dashboard_2.png)

3. Choose the data source and finally import the dashboard

![Choose the data source](/postgres/images/import_dashboard_3.png)

If you followed the instruction properly, you should see the Postgres Grafana dashboard in your Grafana UI.