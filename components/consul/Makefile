# Consul component (Helm)

NAMESPACE ?= consul
RELEASE   ?= consul
CHART     ?= hashicorp/consul

.PHONY: install wait ensure-tools ensure-helm repo uninstall clean

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }

ensure-helm:
	@command -v helm >/dev/null 2>&1 || { echo "[ERR] helm not found"; exit 1; }

repo: ensure-helm
	@helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null
	@helm repo update >/dev/null

install: ensure-tools ensure-helm repo
	@echo "[CONSUL] Context => kind-$(CLUSTER_NAME)"
	kubectl config use-context kind-$(CLUSTER_NAME) >/dev/null
	@echo "[CONSUL] Installing $(RELEASE) via Helm in $(NAMESPACE)"
	helm upgrade --install $(RELEASE) $(CHART) \
	  --namespace $(NAMESPACE) --create-namespace \
	  -f $(CURDIR)/values.yaml
	@$(MAKE) wait
	@$(MAKE) route CLUSTER_NAME=$(CLUSTER_NAME)

wait: ensure-tools
	@echo "[CONSUL] Waiting for server statefulset rollout"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) rollout status statefulset/$(RELEASE)-server --timeout=300s || true
	@echo "[CONSUL] Current pods"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) get pods -l app.kubernetes.io/name=consul || true

route: ensure-tools
	@echo "[CONSUL] Applying HTTPRoute for consul-ui (host: consul.local)"
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(CURDIR)/http-route.yaml

uninstall: ensure-helm
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true
	@kubectl --context kind-$(CLUSTER_NAME) delete -f $(CURDIR)/http-route.yaml --ignore-not-found || true

clean: uninstall
