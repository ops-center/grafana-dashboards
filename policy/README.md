# Policy Grafana Dashboards

There are two dashboards to monitor gatekeeper policy information

- `ACE / Policy / Cluster Violations`: Shows policy violations info in cluster level.
- `ACE / Policy / Namespace Violations`: Shows policy violations info in namespace level.

Note: These dashboards are developed in **Grafana version 7.5.5**

### Installation

Policy Dashboards are heavily dependent on:

- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [gatekeeper](https://github.com/open-policy-agent/gatekeeper)

#### Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Policy Grafana dashboards.

#### Install Gatekeeper

Follow the steps here to install [Gatekeeper](https://github.com/open-policy-agent/gatekeeper/tree/master/charts/gatekeeper)

### Using Dashboards

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `policy` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/policy/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/policy/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the Policy Grafana-dashboard in your Grafana UI.

### Samples

####  ACE / Policy / Cluster Violations

![ACE / Policy / Cluster Violations](/policy/images/cluster-violations.png)
####  ACE / Policy / Namespace Violations

![ACE / Policy / Namespace Violations](/policy/images/namespace-violations.png)

