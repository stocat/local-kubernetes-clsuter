# Metrics component Makefile (Helm - metrics-server)

NAMESPACE 		?= kube-system
RELEASE   		?= metrics-server
CHART     		?= metrics-server/metrics-server
CLUSTER_NAME    ?= stocat-local

.PHONY: install wait ensure-tools ensure-helm repo uninstall clean

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }

ensure-helm:
	@command -v helm >/dev/null 2>&1 || { echo "[ERR] helm not found"; exit 1; }

repo: ensure-helm
	@helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ >/dev/null
	@helm repo update >/dev/null

install: ensure-tools ensure-helm repo
	@echo "[METRICS] Context => kind-$(CLUSTER_NAME)"
	kubectl config use-context kind-$(CLUSTER_NAME) >/dev/null
	@echo "[METRICS] Installing $(RELEASE) via Helm in $(NAMESPACE)"
	helm upgrade --install $(RELEASE) $(CHART) \
	  --namespace $(NAMESPACE) --create-namespace \
	  -f $(CURDIR)/values.yaml
	@$(MAKE) wait

wait: ensure-tools
	@echo "[METRICS] Waiting for metrics-server rollout"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) rollout status deployment/$(RELEASE) --timeout=300s

uninstall: ensure-helm
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true

clean: uninstall
