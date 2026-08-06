# Postgres Grafana Dashboards

There are four dashboards to monitor a Postgres Database managed by KubeDB.

- KubeDB / Postgres / Summary: Shows overall summary of a Postgres instance.
- KubeDB / Postgres / Pod: Shows individual database pod-level information.
- KubeDB / Postgres / Database: shows Postgres internal databases metrics.
- KubeDB / Postgres / Remote Replica: disaster-recovery view of a remote replica cluster streaming from a source in another data center. See the [panel reference](#kubedb--postgres--remote-replica-dashboard) below.

Note: These dashboards are developed in **Grafana version 7.4.5**

### Dependencies

Postgres Dashboards are heavily dependent on:

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Panopticon by Appscode](https://byte.builders/blog/post/introducing-panopticon/)


### Installation

#### 1. Install Prometheus Stack

Install Prometheus stack if you haven't done it already. You can use [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) which installs the necessary components required for the Postgres Grafana dashboards.

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

#### 3. Add monitoring configuration in KubeDB Postgres resource yaml

To enable monitoring of a KubeDB Postgres instance, you have to add monitoring configuration in the Postgres resource yaml spec like below:

```
apiVersion: kubedb.com/v1
kind: Postgres
metadata:
  name: sample-postgres-with-monitoring
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

Now, on your Grafana UI, import the json files of dashboards located in the `postgres` folder of this repository.


1. Select `Import` from the `Plus(+)` icon from the left bar of the Grafana UI

![Import New Dashboard](/postgres/images/import_dashboard_1.png)

2. Upload the json file

![Upload Dashboard JSON](/postgres/images/import_dashboard_2.png)

3. Choose the data source and finally import the dashboard

![Choose the data source](/postgres/images/import_dashboard_3.png)

If you followed the instruction properly, you should see the Postgres Grafana dashboard in your Grafana UI.

## KubeDB / Postgres / Remote Replica dashboard

This dashboard answers one question for a disaster-recovery operator: **is the remote replica protecting you right now?** It is meant for a KubeDB Postgres created with `spec.remoteReplica`, i.e. a cluster in one data center streaming from a source primary in another.

![Remote Replica dashboard during a staged incident drill](/postgres/images/remote_replica_dashboard.png)

The screenshot above was taken during a staged drill against a 3-pod remote replica: a 200 MB replication-lag spike (07:05–07:10), a full node outage of the replica DC (07:26–07:28), and a deliberate divergence healed by `pg_rewind` (07:53–07:54).

### Where the metrics come from

| Source | Port | Metrics |
|---|---|---|
| `pg-coordinator` container (remote-replica mode only) | 23790 (`raft-metrics`) | `pg_coordinator_remote_replica_*` |
| postgres_exporter container | 56790 (`metrics`) | `pg_replication_*`, `pg_stat_activity_count`, ... |
| Panopticon | — | `kubedb_com_postgres_info` (feeds the `app` variable) |

Both ports are exposed by the `<db>-stats` Service and scraped by its ServiceMonitor when `spec.monitor` is set. The coordinator metrics are fed by the coordinator's own monitoring loops — Prometheus scrapes never touch the source database.

The `namespace` and `app` variables select the remote replica cluster (**not** the source). All panels break down per pod.

### Row: DR Protection Status

Five stats, evaluated at the current instant. The three left ones must be green.

- **Streaming** — `min` over pods of `pg_coordinator_remote_replica_streaming`. `1`: every pod is confirmed by the **source** primary in its `pg_stat_replication`. `0`: at least one pod is definitively not streaming — down, diverged, or mid-recovery. This gauge mirrors the pod's `kubedb.com/role: standby` label: both are set only on positive evidence from the source, and a pod loses both the moment it stops being a usable replica. Expect a red dip of roughly 1–2 minutes during any coordinator-driven recovery (see below); sustained red is an incident.
- **Source Reachable** — `min` over pods of `pg_coordinator_remote_replica_source_reachable`. `0` means at least one pod's last attempt to query the source failed: network partition between the DCs, source down, or credentials/TLS broken. A DR replica that cannot see its source is not protecting anything — treat sustained red as severity-1 even though the local cluster looks healthy.
- **Replication Lag (RPO)** — `max` over pods of `pg_coordinator_remote_replica_lag_bytes`: bytes of WAL the source has written beyond what the pod has replayed (`pg_current_wal_lsn()` on the source minus the pod's replay LSN). **This is the data you lose if the source DC is destroyed right now.** Thresholds: yellow at 16 MiB (one WAL segment), red at 128 MiB.
- **Lag Data Age** — seconds since the last successful lag measurement. The lag monitor samples every 5 s while the replica is catching up, and backs off up to 300 s while lag is zero — so **any value up to ~5 minutes is normal for an in-sync replica**. Yellow starts at 330 s. Sustained high values mean the monitor cannot measure at all (usually: source unreachable), i.e. the RPO number next to it is stale — read them together.
- **Recoveries (24h)** — `increase` of `pg_coordinator_remote_replica_recovery_total` over 24 h. Anything ≥ 1 colors the panel: every self-healing action (pg_rewind or pg_basebackup) is worth an incident review even though it succeeded — something made a replica diverge or lose its WAL position. Values like `1.01` are an artifact of Prometheus' `increase()` extrapolation; read it as 1.

### Row: Replication Lag

![Byte lag during a staged 200 MB burst with replay paused](/postgres/images/remote_replica_lag_bytes.png)

- **Lag Behind Source (bytes)** — the per-pod time series behind the RPO stat. Sampling is adaptive: 5 s cadence while lag is non-zero, up to 300 s between samples while in sync. Consequence: a lag spike can appear on the graph up to 5 minutes after it started (first non-zero reading snaps the monitor back to 5 s). In the screenshot, WAL replay was paused on one pod and 213 MB written on the source: the plateau at ~216 MB is one pod; the other two stay at zero; the drop is replay resuming and draining in seconds.
- **Apply Lag (seconds, exporter)** — `pg_replication_lag_seconds` from postgres_exporter: seconds since the last *replayed* transaction. **Caveat: this also grows while the source is idle**, because there is nothing to replay — a quiet source looks identical to a lagging replica. Read it together with the byte panel: bytes at 0 with seconds growing = idle source, harmless; both growing = real lag.

![Apply lag in seconds during the same drill](/postgres/images/remote_replica_apply_lag.png)

### Row: Self-Healing & Replica Health

![Recovery counter stepping 0 to 1 after a deliberate divergence](/postgres/images/remote_replica_recovery.png)

- **Recovery Actions (rate/h)** — `increase` over 1 h of the recovery counter, split by action (`pg_rewind`, `pg_basebackup`) and result (`success`, `failure`). All four series are exported from coordinator start, so flat lines at 0 are the healthy baseline, and any step is a real event. In the screenshot a replica pod was deliberately promoted (divergent timeline); the coordinator detected it within one 15 s tick, ran `pg_rewind` back onto the source timeline, and the `pg_rewind/success` series stepped to 1. `pg_basebackup` series stepping means rewind was not possible and the pod re-seeded from scratch — expect a longer Streaming dip and check why.
- **Replica Mode (is_replica)** — `pg_replication_is_replica` per pod: 1 while in recovery (a standby). A pod at 0 without a planned promotion is an incident — it accepted a divergent timeline. The coordinator will notice (Streaming drops, recovery fires) and rewind it back to 1; the screenshot's brief dips are exactly that plus ordinary restarts.
- **Backend Connections** — total Postgres backends per pod: `pg_stat_activity_count` summed over **all** databases and **all** connection states, sampled at each Prometheus scrape. On an idle remote replica the only sessions are the metrics exporter and the KubeDB health checker, both short-lived — so the graph is an honest sawtooth flapping between 0 and 2 depending on what the scrape instant catches, and legend values such as `avg 1.24` are fractional because they average those samples over the window. What matters is the shape: a sustained band above the 0–2 baseline means clients are connected through the standby service and actually reading from the replica; a sudden drop from that band back to baseline means your read traffic went away.

![Idle-replica sawtooth: only exporter and health-checker sessions](/postgres/images/remote_replica_connections.png)

### Reading incidents from this dashboard

| Symptom | Likely meaning |
|---|---|
| Streaming red, Source Reachable green | A replica pod is down, diverged, or recovering; the coordinator is on it. Watch Recovery Actions. |
| Source Reachable red, everything else green-ish | The DCs are partitioned or the source is down. The replica keeps serving reads from its last state; RPO/lag numbers are stale (watch Lag Data Age). |
| RPO climbing, Streaming green | Replica receives WAL but cannot replay fast enough (or replay is paused). Check disk/CPU on the replica. |
| Apply Lag climbing, byte lag at 0 | Source is idle. Not an incident. |
| Recoveries ≥ 1 | Self-healing fired. Read the coordinator logs of the affected pod; find what caused the divergence. |
| is_replica at 0 | A replica was promoted. If unplanned, this is the incident — the coordinator will rewind the pod back, discarding its divergent writes. |

Note: these dashboards are developed against Grafana 7.5.x; the dashboard renders timestamps in UTC by design (a DR timeline is read across two data centers — local time is ambiguous).
