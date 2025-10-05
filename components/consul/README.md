# Consul Component

Installs HashiCorp Consul via the official Helm chart for basic KV/UI usage on kind. Service mesh features (Connect injection) are disabled to avoid conflicts with Istio.

Chart
- Repo: https://helm.releases.hashicorp.com
- Chart: `hashicorp/consul`

Values (values.yaml)
- `server.replicas: 1`, `server.bootstrapExpect: 1` for local
- `ui.enabled: true` to enable the UI service (ClusterIP by default)
- `connectInject.enabled: false` to prevent Consul sidecar injection (we use Istio)
- `controller.enabled: false`, `meshGateway.enabled: false`

Make targets
- Install: `make install`
- Uninstall: `make uninstall`

HTTPRoute exposure (Gateway API)
- This component also applies an HTTPRoute that exposes Consul UI via Istio Gateway on host `consul.local` (port 80 listener).
- File: `components/consul/http-route.yaml` 
- If you’re using the external NGINX proxy from this repo, add a server block that sets `Host: consul.local` (e.g., on another port) or reuse an existing one.

Accessing the UI
- Port-forward (simple): `kubectl -n consul port-forward svc/consul-ui 8500:80`
- Or create a NodePort/Ingress in your environment if you prefer not to port-forward.
