# Kiali component (Helm) + Prometheus addon

CLUSTER_NAME     ?= stocat-local
NAMESPACE        ?= istio-system
RELEASE          ?= kiali-server
CHART            ?= kiali/kiali-server
AUTH_STRATEGY    ?= anonymous
PROM_ADDON_URL   ?= https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/prometheus.yaml

.PHONY: install wait ensure-tools ensure-helm repo prometheus route uninstall clean

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }

ensure-helm:
	@command -v helm >/dev/null 2>&1 || { echo "[ERR] helm not found"; exit 1; }

repo: ensure-helm
	@helm repo add kiali https://kiali.org/helm-charts >/dev/null
	@helm repo update >/dev/null

prometheus: ensure-tools
	@echo "[KIALI] Ensuring Prometheus addon"
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(PROM_ADDON_URL)

install: ensure-tools ensure-helm repo prometheus
	@echo "[KIALI] Context => kind-$(CLUSTER_NAME)"
	kubectl config use-context kind-$(CLUSTER_NAME) >/dev/null
	@echo "[KIALI] Installing $(RELEASE) via Helm in $(NAMESPACE)"
	helm upgrade --install $(RELEASE) $(CHART) \
	  --namespace $(NAMESPACE) --create-namespace \
	  --set auth.strategy=$(AUTH_STRATEGY)
	@$(MAKE) wait
	@$(MAKE) route CLUSTER_NAME=$(CLUSTER_NAME)

wait: ensure-tools
	@echo "[KIALI] Waiting for Kiali to be ready"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) rollout status deployment/kiali --timeout=240s

route: ensure-tools
	@echo "[KIALI] Applying HTTPRoute for kiali-ui (host: kiali.local)"
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(CURDIR)/http-route.yaml

uninstall: ensure-helm
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true
	@kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) delete httproute/kiali --ignore-not-found || true

clean: uninstall

