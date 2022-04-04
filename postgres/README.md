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
- [Panopticon by Appscode](https://blog.byte.builders/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Postgres Grafana dashboards.

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
    --set monitoring.serviceMonitor.labels.release=helm-release-name-of-kube-prometheus-stack \
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

#### Create Postgres Metrics Configurations

At first, you have to create a `MetricsConfiguration` object for Postgres. This `MetricsConfiguration` object is used by Panopticon to generate metrics for Postgres instances. 

Run the below command to create the `MetricsConfiguration` object:

```bash
kubectl apply -f https://github.com/kubedb/installer/raw/master/charts/kubedb-metrics/templates/metricsconfig-kubedb-com-postgres.yaml
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