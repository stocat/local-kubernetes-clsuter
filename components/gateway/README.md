# Gateway + HTTPRoute Sample

Minimal Gateway API resources to exercise Istio as the ingress using port-based routing on 20080.

Resources
- `gateway.yaml`: Gateway in `istio-system` with listener `http-20080` on port 20080, `gatewayClassName: istio`.
- `http-route.yaml`: HTTPRoute in `default` routing `/*` to Service `echo:80`.
- `sample-app.yaml`: Echo server Deployment + Service for testing.

Make targets
- Apply gateway+route: `make install`
- Deploy app: `make app`
- Clean: `make clean`

Test
- `make app`
- `curl -v http://localhost:20080/`
