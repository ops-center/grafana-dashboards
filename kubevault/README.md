# KubeVault Grafana Dashboards

There are two dashboards to monitor VaultServer managed by KubeVault.

- KubeVault / Summary: Shows overall summary of a VaultServer instance.
- KubeVault / Vault: shows Vault internal metrics such as unseal status, tokens, leases , kv secrets etc.

Note: These dashboards are developed in **Grafana version 7.5.17**

### Dependencies

KubeVault Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by Appscode](https://byte.builders/blog/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the KubeVault Grafana dashboards.

#### 2. Install Panopticon

Install Panopticon if you haven't done it already. Like other AppsCode products, [Panopticon](https://byte.builders/blog/post/introducing-panopticon/) also need a license to run.

**If you already have a license for KubeDB or Stash, you do not need to issue a new license for Panopticon. Your existing KubeDB or Stash license will work with Panopticon.**

Now, install Panopticon using the following commands:

```bash
helm upgrade -i monitoring-operator oci://ghcr.io/appscode-charts/monitoring-operator \
  --version v0.0.4 \
  -n monitoring --create-namespace

helm upgrade -i panopticon oci://ghcr.io/appscode-charts/panopticon \
  --version v2024.2.5 \
  -n monitoring --create-namespace \
  --set-file license=/path/to/license-file.txt
```

#### 3. Add monitoring configuration in KubeVault managed VaultServer spec

To enable monitoring of a KubeVault VaultServer instance, you have to add monitoring configuration in the VaultServer CR spec like below:

```
apiVersion: kubevault.com/v1alpha2
kind: VaultServer
metadata:
  name: vault
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
        interval: 30s
```

### Using Dashboards

#### Create  Metrics Configurations

At first, you have to create a `MetricsConfiguration` object for VaultServer. This `MetricsConfiguration` object is used by Panopticon to generate metrics for VaultServer instances.

Install `kubevault-metrics` charts which will create the `MetricsConfiguration` object for DB:

```bash
helm upgrade -i kubedb-metrics oci://ghcr.io/appscode-charts/kubedb-metrics \
  --version v2023.12.28 \
  -n kubedb --create-namespace
```

#### Import Grafana Dashboard

Now, on your Grafana UI, import the json files of dashboards located in the `kubevault` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/kubevault/images/import_dashboard_1.png)

2. Upload the json file and hit load button:

![Upload Dashboard JSON](/kubevault/images/import_dashboard_2.png)


If you followed the instruction properly, you should see the KubeVault Grafana dashboard in your Grafana UI.

### Samples

####  KubeVault / VaultServer / Summary

![KubeVault / VaultServer / Summary](/kubevault/images/VaultServerSummary1.png)
![KubeVault / VaultServer / Summary](/kubevault/images/VaultServerSummary2.png)
