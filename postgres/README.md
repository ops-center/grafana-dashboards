# Postgres Grafana Dashboard

There are three dashboards to monitor Postgres Database health.

- KubeDB / Postgres / Summary: shows Postgres resource level information
- KubeDB / Postgres / Pods: shows individual database pod level information
- KubeDB / Postgres / Databases: shows Postgres internal databases metrics 

## Installation process

Postgres Dashboards are heavily depends on:

- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Panopticon by Appscode](https://blog.byte.builders/post/introducing-panopticon/)

