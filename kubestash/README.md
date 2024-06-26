# KubeStash Grafana Dashboard

### Dependencies

KubeStash Grafana Dashboard heavily depends on the following projects.

- [Prometheus node-exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by AppsCode](https://github.com/kubeops/installer/tree/master/charts/panopticon)

### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the KubeStash Grafana dashboard.

#### 2. Install Panopticon

Like other AppsCode products, [Panopticon](https://byte.builders/blog/post/introducing-panopticon/) also needs a license to run.

**If you already have a license for KubeDB or KubeStash, you do not need to issue a new license for Panopticon. Your existing KubeDB or KubeStash license will work with Panopticon.**

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

### Using Dashboard

At first, let's port-forward the respective service for the Grafana dashboard so that we can access it through our browser locally.

```bash
❯ kubectl port-forward -n monitoring service/prometheus-stack-grafana 3000:80
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```
Now, go to [http://localhost:3000](http://localhost:3000/) in your browser and login to your Grafana UI. The default username and password should be `admin`, and `prom-operator` respectively.

Then, on the Grafana UI, click the `+` icon from the left sidebar and then click on `Import` button as below,

![Import New Dashboard](/kubestash/images/import_dashboard_1.png)

Then, on the import UI, you can either upload the `kubestash_dashboard.json` file by clicking the `Upload JSON file` button or you can paste the content of the JSON file in the text area labeled as `Import via panel json`.

![Upload Dashboard JSON](/kubestash/images/import_dashboard_2.png)

If you followed the instruction properly, you should see the KubeStash Grafana dashboard in your Grafana UI.

![KubeStash Grafana](/kubestash/images/kubestash_grafana_dashboard.png)
