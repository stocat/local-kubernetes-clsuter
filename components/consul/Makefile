# Consul component (Helm)

NAMESPACE        ?= consul
RELEASE          ?= consul
CHART            ?= hashicorp/consul
CLUSTER_NAME     ?= kind-local
KV_PATH          ?= config/common/secrets/jwt-secret
JWT_SECRET       ?= replace-with-a-strong-secret-32-bytes-min
KV_ROUTES_PATH   ?= config/gateway/routes.yaml

.PHONY: install wait ensure-tools ensure-helm repo uninstall clean

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }
	@command -v envsubst >/dev/null 2>&1 || { echo "[ERR] envsubst not found. Install gettext (e.g., 'brew install gettext' then 'brew link --force gettext', or 'apt-get install gettext-base')."; exit 1; }

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
	@$(MAKE) kv CLUSTER_NAME=$(CLUSTER_NAME) JWT_SECRET='$(JWT_SECRET)' KV_PATH='$(KV_PATH)'
	@$(MAKE) kv-routes CLUSTER_NAME=$(CLUSTER_NAME) KV_ROUTES_PATH='$(KV_ROUTES_PATH)'

wait: ensure-tools
	@echo "[CONSUL] Waiting for server statefulset rollout"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) rollout status statefulset/$(RELEASE)-server --timeout=300s || true
	@echo "[CONSUL] Current pods"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) get pods -l app.kubernetes.io/name=consul || true

route: ensure-tools
	@echo "[CONSUL] Applying HTTPRoute for consul-ui (host: consul.local)"
	kubectl --context kind-$(CLUSTER_NAME) apply -f $(CURDIR)/http-route.yaml

kv: ensure-tools
	@echo "[CONSUL] Seeding KV at $(KV_PATH)"
	KV_PATH='$(KV_PATH)' JWT_SECRET='$(JWT_SECRET)' envsubst < $(CURDIR)/kv-job.yaml | \
	  kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) apply -f -
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) wait --for=condition=complete job/consul-kv-init --timeout=180s || \
	  (echo "[CONSUL] KV init job did not complete" && exit 1)

routes-configmap: ensure-tools
	@echo "[CONSUL] (Re)creating routes ConfigMap from routes.yaml"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) create configmap consul-kv-routes \
	  --from-file=routes.yaml=$(CURDIR)/routes.yaml -o yaml --dry-run=client | \
	  kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) apply -f -

kv-routes: ensure-tools routes-configmap
	@echo "[CONSUL] Seeding KV routes at $(KV_ROUTES_PATH)"
	KV_ROUTES_PATH='$(KV_ROUTES_PATH)' envsubst < $(CURDIR)/kv-routes-job.yaml | \
	  kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) apply -f -
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) wait --for=condition=complete job/consul-kv-routes --timeout=180s || \
	  (echo "[CONSUL] KV routes job did not complete" && exit 1)

uninstall: ensure-helm
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true
	@kubectl --context kind-$(CLUSTER_NAME) delete -f $(CURDIR)/http-route.yaml --ignore-not-found || true
	@kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) delete job/consul-kv-init --ignore-not-found || true
	@kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) delete job/consul-kv-routes --ignore-not-found || true
	@kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) delete configmap/consul-kv-routes --ignore-not-found || true

clean: uninstall
