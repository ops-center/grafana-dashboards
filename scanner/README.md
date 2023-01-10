# Scanner Grafana Dashboards

There are four dashboards to monitor scanning information

- `Appscode / Scanner / Cluster CVEs`: Shows vulnerability info in cluster level.
- `Appscode / Scanner / Namespace CVEs`: Shows vulnerability info in namespace level.
- `Appscode / Scanner / Image CVEs`: Shows vulnerability info for a particular image.
- `Appscode / Scanner / App CVEs`: Shows vulnerability info for a particular workload. Ex: MongoDB, Deployment, ReplicaSet etc.
- `Appscode / Scanner / CVE Details`: Shows the occurrence information of a particular CVE, both in cluster level & namespace level.

Note: These dashboards are developed in **Grafana version 7.5.11**

### Dependencies

Scanner Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Scanner Grafana dashboards.

#### 2. Add monitoring configuration in a KubeDB-managed Database spec

Let's say, You want to monitor a kubeDB managed MongoDB. To enable monitoring in that instance, you have to add monitoring configuration in the MongoDB CR spec like below:

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
Now, this db will be used as a workload in the `Appscode / Scanner / App CVEs` dashboard. And you can monitor the vulnerabilities for the images under this db.

### Using Dashboards

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `scanner` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/scanner/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/scanner/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the Scanner Grafana dashboard in your Grafana UI.

### Samples

####  Appscode / Scanner / Cluster CVEs

![Appscode / Scanner / Cluster CVEs](/scanner/images/cluster-level-cves.png)

####  Appscode / Scanner / Image CVEs

![Appscode / Scanner / Image CVEs](/scanner/images/image-level-cves.png)


####  Appscode / Scanner / Namespace CVEs

![Appscode / Scanner / Namespace CVEs](/scanner/images/namespace-level-cves.png)

####  Appscode / Scanner / App CVEs

![Appscode / Scanner / App CVEs](/scanner/images/app-level-cves.png)

#### Appscode / Scanner / CVE Details
![Appscode / Scanner / CVE Details](/scanner/images/cve-details.png)
