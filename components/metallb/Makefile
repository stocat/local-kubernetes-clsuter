# MetalLB component (optional for LoadBalancer services on kind)

.PHONY: ensure-tools ensure-helm repo install wait uninstall apply-pool

NAMESPACE ?= metallb-system
RELEASE   ?= metallb
CHART     ?= metallb/metallb
# Example: IP_RANGE=172.18.255.200-172.18.255.250
IP_RANGE  ?=

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }

ensure-helm:
	@command -v helm >/dev/null 2>&1 || { echo "[ERR] helm not found"; exit 1; }

repo: ensure-helm
	@helm repo add metallb https://metallb.github.io/metallb >/dev/null
	@helm repo update >/dev/null

install: ensure-tools ensure-helm repo
	@echo "[METALLB] Context => kind-$(CLUSTER_NAME)"
	kubectl config use-context kind-$(CLUSTER_NAME) >/dev/null
	@echo "[METALLB] Installing $(RELEASE) via Helm in $(NAMESPACE)"
	helm upgrade --install $(RELEASE) $(CHART) --namespace $(NAMESPACE) --create-namespace
	@$(MAKE) wait
	@if [ -n "$(IP_RANGE)" ]; then \
	  $(MAKE) apply-pool CLUSTER_NAME=$(CLUSTER_NAME) IP_RANGE=$(IP_RANGE); \
	else \
	  echo "[METALLB] Skipping IP pool; set IP_RANGE=START-END to create one"; \
	fi

wait: ensure-tools
	@echo "[METALLB] Waiting for controller and speaker"
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) rollout status deploy/$(RELEASE)-controller --timeout=240s
	kubectl --context kind-$(CLUSTER_NAME) -n $(NAMESPACE) rollout status ds/$(RELEASE)-speaker --timeout=240s

apply-pool: ensure-tools
	@if [ -z "$(IP_RANGE)" ]; then echo "[ERR] Set IP_RANGE=START-END (e.g., 172.18.255.200-172.18.255.250)"; exit 1; fi
	@echo "[METALLB] Applying IPAddressPool $(IP_RANGE)"
	sed "s/__IP_RANGE__/$(IP_RANGE)/g" $(CURDIR)/pool.yaml | kubectl --context kind-$(CLUSTER_NAME) apply -f -

uninstall: ensure-tools
	@kubectl --context kind-$(CLUSTER_NAME) delete -f $(CURDIR)/pool.yaml --ignore-not-found || true
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true

