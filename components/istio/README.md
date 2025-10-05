# Istio Component

Istio is installed via istioctl with Gateway API enabled and cluster-wide auto sidecar injection. The classic istio-ingressgateway is disabled; instead, a Kubernetes Gateway (managed by Istio) is used.

Key behavior
- Enables Gateway API in Pilot: `PILOT_ENABLE_GATEWAY_API=true`.
- Enables cluster-wide auto injection: `enableNamespacesByDefault=true`.
- Disables the legacy istio-ingressgateway deployment from istioctl.
- Gateway API controller creates a managed Service/Deployment for the Gateway; Makefile patches the Service to NodePort and fixes ports when needed.

Make targets
- `make install`
- `make uninstall`
- Namespace control:
  - Exclude namespace from injection: `make exclude-namespace NAMESPACE=<ns>` (adds label `istio-injection=disabled`)
  - Re-include namespace: `make include-namespace NAMESPACE=<ns>` (removes exclusion label)

Notes
- Pods already running must be restarted for injection policy to take effect: `kubectl -n <ns> rollout restart deploy/<name>`.
- For TLS listeners on 20443, add a Gateway listener with TLS and reference a Secret.
