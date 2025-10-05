# Metrics Component (metrics-server)

Installs the official metrics-server Helm chart so k9s can show CPU/Memory metrics.

Chart
- Repo: `https://kubernetes-sigs.github.io/metrics-server/`
- Chart: `metrics-server/metrics-server`

Values
- `components/metrics/values.yaml` sets:
  - `apiService.create: true`
  - `args`: `--kubelet-insecure-tls`, `--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP`

Make targets
- Install: `make install`
- Uninstall: `make uninstall`

Verify
- `kubectl -n kube-system rollout status deploy/metrics-server`
- k9s should show live node/pod metrics.
