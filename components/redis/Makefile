# Redis component (Bitnami Helm chart)

NAMESPACE     ?= data
RELEASE       ?= redis
CHART         ?= bitnami/redis
VALUES_FILE   ?= $(CURDIR)/values.yaml
CLUSTER_NAME  ?= stocat-local

.PHONY: install uninstall clean template ensure-tools ensure-helm repo wait ns

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }

ensure-helm:
	@command -v helm >/dev/null 2>&1 || { echo "[ERR] helm not found"; exit 1; }

repo: ensure-helm
	@helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null
	@helm repo update >/dev/null

ns: ensure-tools
	kubectl --context kind-$(CLUSTER_NAME) get ns $(NAMESPACE) >/dev/null 2>&1 || \
	  kubectl --context kind-$(CLUSTER_NAME) create ns $(NAMESPACE)
	kubectl --context kind-$(CLUSTER_NAME) label ns $(NAMESPACE) istio-injection=disabled --overwrite >/dev/null 2>&1 || true

install: ensure-tools ensure-helm repo ns
	@echo "[REDIS] Installing release '$(RELEASE)' into namespace '$(NAMESPACE)'"
	kubectl config use-context kind-$(CLUSTER_NAME) >/dev/null
	helm upgrade --install $(RELEASE) $(CHART) \
	  --namespace $(NAMESPACE) --create-namespace \
	  -f $(VALUES_FILE)
	@$(MAKE) wait

wait: ensure-tools
	@echo "[REDIS] Waiting for pods (instance=$(RELEASE))"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) wait --for=condition=ready pod -l app.kubernetes.io/instance=$(RELEASE) --timeout=300s || true
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) get pods -l app.kubernetes.io/instance=$(RELEASE) || true

template: ensure-helm repo
	helm template $(RELEASE) $(CHART) -f $(VALUES_FILE)

uninstall: ensure-helm ensure-tools
	@echo "[REDIS] Uninstalling release '$(RELEASE)' from namespace '$(NAMESPACE)'"
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true

clean: uninstall
