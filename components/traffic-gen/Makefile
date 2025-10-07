CLUSTER_NAME        ?= kind-local
NAMESPACE           ?= default

# Traffic settings (override as needed)
TARGET_BASE_URL     ?= http://istio-ingressgateway-istio.istio-system.svc.cluster.local:80
HOST_HEADER         ?=
PATHS               ?= catalog/catalogs,order/orders
INTERVAL_MS         ?= 1000
CONCURRENCY         ?= 1
JWT_SECRET          ?= replace-with-a-strong-secret-32-bytes-min

.PHONY: install uninstall clean ensure-tools

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }
	@command -v envsubst >/dev/null 2>&1 || { echo "[ERR] envsubst not found. Install gettext (e.g., 'brew install gettext' then 'brew link --force gettext', or 'apt-get install gettext-base')."; exit 1; }

install: ensure-tools
	@echo "[TRAFFIC] Installing traffic generator into namespace '$(NAMESPACE)'"
	TARGET_BASE_URL='$(TARGET_BASE_URL)' HOST_HEADER='$(HOST_HEADER)' PATHS='$(PATHS)' \
	INTERVAL_MS='$(INTERVAL_MS)' CONCURRENCY='$(CONCURRENCY)' JWT_SECRET='$(JWT_SECRET)' \
	envsubst < $(CURDIR)/deployment.yaml | \
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) apply -f -

uninstall: ensure-tools
	@echo "[TRAFFIC] Removing traffic generator"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) delete -f $(CURDIR)/deployment.yaml --ignore-not-found || true

clean: uninstall

