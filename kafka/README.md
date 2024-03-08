# Kafka Grafana Dashboards

There is a dashboard to monitor Kafka instances managed by KubeDB.
- KubeDB / Kafka / Database: shows Kafka internal metrics.

Note: These dashboards are developed in **Grafana version 7.5.5**

### Dependencies

Kafka Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [Prometheus JMX Exporter](https://github.com/prometheus/jmx_exporter)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Kafka Grafana dashboards.

#### 2. Add monitoring configuration in KubeDB managed Kafka spec

To enable monitoring of a KubeDB Kafka instance, you have to add monitoring configuration in the Kafka CR spec like below:

```
apiVersion: kubedb.com/v1alpha2
kind: Kafka
metadata:
  name: sample-kf
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

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `kafka` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/kafka/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/kafka/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the Kafka Grafana dashboard in your Grafana UI.

### Samples

#### KubeDB / Kafka / Database

![KubeDB / Kafka / Database](/kafka/images/Kafka-server-metrics-0.png)
![KubeDB / Kafka / Database](/kafka/images/kafka-server-metrics-1.png)
![KubeDB / Kafka / Database](/kafka/images/Kafka-broker-topic-metrics-0.png)
![KubeDB / Kafka / Database](/kafka/images/kafka-broker-topic-metrics-1.png)
![KubeDB / Kafka / Database](/kafka/images/Kafka-broker-topic-metrics-2.png)
![KubeDB / Kafka / Database](/kafka/images/kafka-kraft-quorum-monitoring-metrics.png)
![KubeDB / Kafka / Database](/kafka/images/kafka-kraft-controller-monitoring-metrics.png)
