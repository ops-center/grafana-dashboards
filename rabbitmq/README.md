# Grafana Dashboards

There are three dashboards to monitor RabbitMQ Databases managed by KubeDB.

- KubeDB / RabbitMQ / Summary: Shows overall summary of a RabbitMQ instance.
- KubeDB / RabbitMQ / Database: Shows RabbitMQ internal metrics for an instance.
- KubeDB / RabbitMQ / Pod: Shows individual pod-level information.

Note: These dashboards are developed and tested in **Grafana version 8.0.7**

### Dependencies

RabbitMQ Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by Appscode](https://byte.builders/blog/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the RabbitMQ Grafana dashboards.

#### 2. Install Panopticon

Install Panopticon if you haven't done it already. Like other AppsCode products, [Panopticon](https://byte.builders/blog/post/introducing-panopticon/) also need a license to run.

**If you already have a license for KubeDB or Stash, you do not need to issue a new license for Panopticon. Your existing KubeDB or Stash license will work with Panopticon.**

Now, install Panopticon using the following commands:

```bash
helm upgrade -i monitoring-operator oci://ghcr.io/appscode-charts/monitoring-operator \
  --version v2024.9.30 \
  -n monitoring --create-namespace

helm upgrade -i panopticon oci://ghcr.io/appscode-charts/panopticon \
  --version v2024.9.30 \
  -n monitoring --create-namespace \
  --set-file license=/path/to/license-file.txt
```

#### 3. Add monitoring configuration in KubeDB managed RabbitMQ spec

To enable monitoring of a KubeDB RabbitMQ instance, you have to add monitoring configuration in the RabbitMQ CR spec like below:

```
apiVersion: kubedb.com/v1alpha2
kind: RabbitMQ
metadata:
  name: sample-rabbitmq
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
helm upgrade -i kubedb-metrics oci://ghcr.io/appscode-charts/kubedb-metrics \
  --version v2024.9.30 \
  -n kubedb --create-namespace
```

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `rabbitmq` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/rabbitmq/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/rabbitmq/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the RabbitMQ Grafana dashboard in your Grafana UI.

### Samples

####  KubeDB / RabbitMQ / Summary

![KubeDB / RabbitMQ / Summary](/rabbitmq/images/rabbitmq-summary-1.png)
![KubeDB / RabbitMQ / Summary](/rabbitmq/images/rabbitmq-summary-2.png)
![KubeDB / RabbitMQ / Summary](/rabbitmq/images/rabbitmq-summary-3.png)

#### KubeDB / RabbitMQ / Database

![KubeDB / RabbitMQ / Database](/rabbitmq/images/rabbitmq-database-1.png)
![KubeDB / RabbitMQ / Database](/rabbitmq/images/rabbitmq-database-2.png)
![KubeDB / RabbitMQ / Database](/rabbitmq/images/rabbitmq-database-3.png)
![KubeDB / RabbitMQ / Database](/rabbitmq/images/rabbitmq-database-4.png)
![KubeDB / RabbitMQ / Database](/rabbitmq/images/rabbitmq-database-5.png)

#### KubeDB / RabbitMQ / Pod

![KubeDB / RabbitMQ / Pod](/rabbitmq/images/rabbitmq-pod-1.png)
![KubeDB / RabbitMQ / Pod](/rabbitmq/images/rabbitmq-pod-2.png)
