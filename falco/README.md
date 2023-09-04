# Falco Grafana Dashboards

There are four dashboards to monitor falco information

- `ACE / Falco / Cluster Events`: Shows falco event info in cluster level.
- `ACE / Falco / Namespace Events`: Shows falco event info in namespace level.
- `ACE / Falco / Node Events`: Shows falco event info in node level.
- `ACE / Falco / App Events`: Shows falco event info in application level.

Note: These dashboards are developed in **Grafana version 7.5.5**

### Dependencies

Falco Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Falco Grafana dashboards.

#### 2. Install Falco & Falco Exporter

Follow the steps here to install [Falco](https://github.com/falcosecurity/charts/tree/master)


#### 3. Install falco-ui-server

Follow the steps here to install [Falco-UI-Server](https://github.com/kubeops/installer/tree/master/charts/falco-ui-server)

### Using Dashboards

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `falco` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/falco/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/falco/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the falco Grafana-dashboard in your Grafana UI.

### Samples

####  ACE / Falco / Cluster Events

![ACE / Falco / Cluster Events](/falco/images/cluster-events.png)
####  ACE / Falco / Namespace Events

![ACE / Falco / Namespace Events](/falco/images/namespace-events.png)


####  ACE / Falco / Node Events

![ACE / Falco / Node Events](/falco/images/node-events.png)

####  ACE / Falco / App Events

![ACE / Falco / App Events](/falco/images/app-events.png)