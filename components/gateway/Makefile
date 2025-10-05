CLUSTER_NAME ?= kind-local

.PHONY: install uninstall clean app ensure-tools gateway-api

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }

gateway-api: ensure-tools
	@echo "[ISTIO] Installing/ensuring Gateway API CRDs (v1.1.0)"
	kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0"

install: ensure-tools gateway-api
	@echo "[GATEWAY] Pre-creating NodePort Service (avoid LB)"
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(CURDIR)/gateway-svc.yaml
	@echo "[GATEWAY] Applying Gateway and HTTPRoute"
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(CURDIR)/gateway.yaml
	

app: ensure-tools
	@echo "[GATEWAY] Deploying sample echo app"
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(CURDIR)/http-route.yaml
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(CURDIR)/sample-app.yaml

uninstall: ensure-tools
	@echo "[GATEWAY] Deleting HTTPRoute and Gateway"
	kubectl --context kind-$(CLUSTER_NAME) delete -f $(CURDIR)/http-route.yaml --ignore-not-found
	kubectl --context kind-$(CLUSTER_NAME) delete -f $(CURDIR)/gateway.yaml --ignore-not-found

clean: uninstall
	@echo "[GATEWAY] Deleting sample app"
	kubectl --context kind-$(CLUSTER_NAME) delete -f $(CURDIR)/sample-app.yaml --ignore-not-found
