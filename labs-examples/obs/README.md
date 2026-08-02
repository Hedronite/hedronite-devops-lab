# Observability: Prometheus and Grafana, two ways

The same stack runs at two scales. In-container binaries answer "what does this metric look like right now" in seconds. The helm chart answers "what does a persistent monitoring stack on a cluster look like." Learn the first before the second; the chart is the binary plus operations.

## Scratch mode (in-container)

The image ships `prometheus` and `grafana-server` as plain binaries. Copy the example, then start Prometheus against the shipped scrape config:

```bash
cp -r /workspace/hedronite-devops-lab/labs-examples/obs /workspace/obs-hello
cd /workspace/obs-hello
prometheus --config.file=prometheus.yml --storage.tsdb.path=/workspace/obs-hello/data &
```

The config scrapes Prometheus itself and a node-exporter expected at `hedronite-devops-lab:9100`. If the node runs no exporter yet, install it there first, or point the target at any host on the mesh that does. Check target health at `http://localhost:9090/targets` with k9s-style patience: a target needs one scrape interval before it reports up.

Start Grafana in a second pane (tmux is in the image for exactly this):

```bash
grafana server --homepath /opt/grafana &
```

Log in at `http://localhost:3000` with admin/admin, add a Prometheus data source at `http://localhost:9090`, then import `dashboards/hello.json`. Two panels appear: load average and available memory on the lab node. When the container exits, all of it evaporates except what you wrote under `/workspace`. That is the design, not a defect.

## Cluster mode (kube-prometheus-stack)

For monitoring that outlives the container, install the chart on the lab node using the values file this repo ships:

```bash
cd /workspace/hedronite-devops-lab/helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
kubectl -n monitoring create secret generic grafana-admin --from-literal=admin-user=admin --from-literal=admin-password=<REPLACE_ME>
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring -f prom-stack-values.yaml
```

The values file pins 15-day retention, `local-path` storage, and disables the control-plane probes k3s embeds. Read its comments before installing anywhere that matters.

Verify:

```bash
kubectl -n monitoring get pods
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```

Same Grafana, same dashboards, different lifetime. The scratch stack dies with the container; the chart stack dies when you tell it to.
