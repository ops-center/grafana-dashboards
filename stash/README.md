# Stash Grafana Dashboard

Stash Grafana Dashboard is available only to Stash Enterprise users. You must install **Stash Enterprise** edition to use/try this dashboard.

### Dependencies

Stash Grafana Dashboard heavily depends on the following projects.

- [Prometheus node-exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by AppsCode](https://github.com/kubeops/installer/tree/master/charts/panopticon)

### Installation


#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the MariaDB Grafana dashboards.

#### 2. Install Panopticon

Like other AppsCode products, [Panopticon](https://byte.builders/blog/post/introducing-panopticon/) also needs a license to run.

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

Make sure to use the appropriate label in `monitoring.serviceMonitor.labels` field according to your setup. This label is used by the Prometheus server to select the desired ServiceMonitor.

#### 3. Install / Upgrade Stash to Enable Monitoring

Now, install Stash Enterprise edition with monitoring enabled. You can follow the following guide for detailed instructions on enabling monitoring in Stash from [here](https://stash.run/docs/laster/guides/latest/monitoring/prometheus_operator/#enable-monitoring-in-stash).

- **New Installation**

```bash
$ helm install stash appscode/stash -n kube-system \
--version v2022.05.18 \
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

At first, let's port-forward the respective service for the Grafana dashboard so that we can access it through our browser locally.

```bash
❯ kubectl port-forward -n monitoring service/prometheus-stack-grafana 3000:80
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```
Now, go to [http://localhost:3000](http://localhost:3000/) in your browser and login to your Grafana UI. The default username and password should be `admin`, and `prom-operator` respectively.

Then, on the Grafana UI, click the `+` icon from the left sidebar and then click on `Import` button as below,

![Import New Dashboard](/stash/images/import_dashboard_1.png)

Then, on the import UI, you can either upload the `stash_dashboard.json` file by clicking the `Upload JSON file` button or you can paste the content of the JSON file in the text area labeled as `Import via panel json`.

![Upload Dashboard JSON](/stash/images/import_dashboard_2.png)

If you followed the instruction properly, you should see the Stash Grafana dashboard in your Grafana UI.

![Stash Grafana](/stash/images/stash_grafana_dashboard.png)
