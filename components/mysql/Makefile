# MySQL component (custom Helm chart)

NAMESPACE     ?= data
RELEASE       ?= mysql
CHART_PATH    ?= $(CURDIR)/chart
VALUES_FILE   ?= $(CURDIR)/values.yaml
CLUSTER_NAME  ?= stocat-local

.PHONY: install uninstall clean template ensure-tools ensure-helm wait ns

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }

ensure-helm:
	@command -v helm >/dev/null 2>&1 || { echo "[ERR] helm not found"; exit 1; }

ns: ensure-tools
	kubectl --context kind-$(CLUSTER_NAME) get ns $(NAMESPACE) >/dev/null 2>&1 || \
	  kubectl --context kind-$(CLUSTER_NAME) create ns $(NAMESPACE)
	kubectl --context kind-$(CLUSTER_NAME) label ns $(NAMESPACE) istio-injection=disabled --overwrite >/dev/null 2>&1 || true

install: ensure-tools ensure-helm ns
	@echo "[MYSQL] Installing release '$(RELEASE)' into namespace '$(NAMESPACE)'"
	kubectl config use-context kind-$(CLUSTER_NAME) >/dev/null
	helm upgrade --install $(RELEASE) $(CHART_PATH) \
	  --namespace $(NAMESPACE) --create-namespace \
	  -f $(VALUES_FILE)
	@$(MAKE) wait

wait: ensure-tools
	@echo "[MYSQL] Waiting for Deployments (instance=$(RELEASE))"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) rollout status deployment/$(RELEASE) --timeout=300s || true
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) get pods -l app.kubernetes.io/instance=$(RELEASE) || true

template: ensure-helm
	helm template $(RELEASE) $(CHART_PATH) -f $(VALUES_FILE)

uninstall: ensure-helm ensure-tools
	@echo "[MYSQL] Uninstalling release '$(RELEASE)' from namespace '$(NAMESPACE)'"
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true

clean: uninstall
