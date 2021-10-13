# Stash Grafana Dashboard

Stash Grafana Dashboard is available only to Stash Enterprise users. You must install **Stash Enterprise** edition to use/try this dashboard.

### Dependencies

Stash Grafana Dashboard heavily depends on the following projects.

- [Prometheus node-exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by AppsCode](https://github.com/kubeops/installer/tree/master/charts/panopticon)

### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done already. You can use use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for Stash Grafana dashboard.

#### 2. Install Panopticon

Like other AppsCode products, [Panopticon](https://blog.byte.builders/post/introducing-panopticon/) also need a license to to run. You can grab a 30 days trial license for Panopticon from [here](https://license-issuer.appscode.com/?p=panopticon-enterprise).

**If you already have an enterprise license for KubeDB or Stash, you do not need to issue a new license for Panopticon. Your existing KubeDB or Stash license will work with Panopticon.**

Now, install Panopticon using the following commands:

```bash
$ helm repo add appscode https://charts.appscode.com/stable/
$ helm repo update

$ helm install panopticon appscode/panopticon -n kubeops \
    --create-namespace \
    --set monitoring.enabled=true \
    --set monitoring.agent=prometheus.io/operator \
    --set monitoring.serviceMonitor.labels.release=prometheus-stack \
    --set-file license=/path/to/license-file.txt
```

#### 3. Install / Upgrade Stash to Enable Monitoring

Now, install Stash Enterprise edition with monitoring enabled. You can follow the following guide for detailed instructions on enabling monitoring in Stash from [here](https://stash.run/docs/laster/guides/latest/monitoring/prometheus_operator/#enable-monitoring-in-stash).

- **New Installation**

```bash
$ helm install stash appscode/stash -n kube-system \
--version v2021.10.11 \
--set features.enterprise=true               \
--set stash-enterprise.monitoring.agent=prometheus.io/operator \
--set stash-enterprise.monitoring.backup=true \
--set stash-enterprise.monitoring.operator=true \
--set stash-enterprise.monitoring.serviceMonitor.labels.release=prometheus-stack \
--set-file global.license=/path/to/license-file.txt
```

- **Existing Installation**

```bash
$ helm upgrade stash appscode/stash -n kube-system \
--reuse-values \
--set stash-enterprise.monitoring.agent=prometheus.io/operator \
--set stash-enterprise.monitoring.backup=true \
--set stash-enterprise.monitoring.operator=true \
--set stash-enterprise.monitoring.serviceMonitor.labels.release=prometheus-stack
```

### Using Dashboard

Now, on your Grafana UI import the `stash_dashboard.json` file located in `stash` folder of this repository.

![Import New Dashboard](/stash/images/import_dashboard_1.png)
![Upload Dashboard JSON](/stash/images/import_dashboard_2.png)

If you followed the instruction properly, you should see the Stash Grafana dashboard in your Grafana UI.

![Stash Grafana](/stash/images/stash_grafana_dashboard.png)
