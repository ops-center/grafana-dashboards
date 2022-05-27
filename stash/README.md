# Stash Grafana Dashboard

Stash Grafana Dashboard is available only to Stash Enterprise users. You must install **Stash Enterprise** edition to use/try this dashboard.

### Dependencies

Stash Grafana Dashboard heavily depends on the following projects.

- [Prometheus node-exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by AppsCode](https://github.com/kubeops/installer/tree/master/charts/panopticon)

### Installation

#### 1. Install Prometheus Stack

At first, you have to install Prometheus operator in your cluster. We are going to install Prometheus operator from [prometheus-community/kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) in monitoring namespace.

Install `prometheus-community/kube-prometheus-stack` chart as below,

- Add necessary helm repositories.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

- Install `kube-prometheus-stack` chart.

```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring
```

This chart will install [prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator), [kubernetes/kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), [prometheus/node_exporter](https://github.com/prometheus/node_exporter), and [grafana/grafana](https://github.com/grafana/grafana) etc.

The above chart will also deploy a Prometheus server. Verify that the Prometheus server has been deployed by the following command:

```bash
❯ kubectl get prometheus -n monitoring
NAME                                    VERSION   REPLICAS   AGE
prometheus-stack-kube-prom-prometheus   v2.28.1   1          69m
```

The above chart will also create a Service for the Prometheus server so that we can access the Prometheus Web UI. Let's verify the Service has been created,

```bash
$ kubectl get service -n monitoring
NAME                                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                       ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   10m
prometheus-operated                         ClusterIP   None             <none>        9090/TCP                     10m
prometheus-stack-grafana                    ClusterIP   10.105.244.221   <none>        80/TCP                       11m
prometheus-stack-kube-prom-alertmanager     ClusterIP   10.97.172.208    <none>        9093/TCP                     11m
prometheus-stack-kube-prom-operator         ClusterIP   10.97.94.139     <none>        443/TCP                      11m
prometheus-stack-kube-prom-prometheus       ClusterIP   10.105.123.218   <none>        9090/TCP                     11m
prometheus-stack-kube-state-metrics         ClusterIP   10.96.52.8       <none>        8080/TCP                     11m
prometheus-stack-prometheus-node-exporter   ClusterIP   10.107.204.248   <none>        9100/TCP                     11m
```

Here, we can use the `prometheus-stack-kube-prom-prometheus` Service to access the Web UI of our Prometheus Server.

#### 2. Install Panopticon

Like other AppsCode products, [Panopticon](https://blog.byte.builders/post/introducing-panopticon/) also needs a license to run. You can grab a 30 days trial license for Panopticon from [here](https://license-issuer.appscode.com/?p=panopticon-enterprise).

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
