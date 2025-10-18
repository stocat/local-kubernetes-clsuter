# Simple Makefile to manage a local Kubernetes cluster with kind

# -------- Variables --------
CLUSTER_NAME ?= kind-local
KIND_CONFIG  ?= config/kind-config.yaml
# Pin a known-good kind node image; override if you need another K8s version
# Use a recent Kubernetes version for kind nodes (override as needed)
KIND_NODE_IMAGE ?= kindest/node:v1.34.0

# Addon versions (override as needed)
ISTIO_PROFILE   ?= minimal
ISTIO_VERSION   ?= 1.27.1

.PHONY: help create delete status kubectx load \
        metrics istio gateway consul kiali traffic traffic-local metallb proxy all-istio clean \
        ensure-tools ensure-helm

help:
	@echo "Targets:"
	@echo "  make create         Create kind cluster ($(CLUSTER_NAME))"
	@echo "  make delete         Delete kind cluster ($(CLUSTER_NAME))"
	@echo "  make status         Show cluster info"
	@echo "  make kubectx        Print kubectl context name"
	@echo "  make load IMAGE=..  Load a local Docker image into the cluster"
	@echo "  make metrics        Install metrics-server (Helm)"
	@echo "  make istio          Install Istio (istioctl, profile=$(ISTIO_PROFILE))"
	@echo "  make gateway        Apply Gateway + HTTPRoute (Gateway API)"
	@echo "  make consul         Install Consul (Helm)"
	@echo "  make kiali          Install Kiali + Prometheus + HTTPRoute"
	@echo "  make traffic        Install traffic generator (JWT to /catalog,/order)"
	@echo "  make traffic-local  Run local traffic generator (Node.js)"
	@echo "  make metallb        Install MetalLB (optional, for LoadBalancer services)"
	@echo "  make proxy          Run external NGINX (20080/20443 -> 32080/32443)"
	@echo "  make all-istio      Create cluster + metrics + Istio"
	@echo "  make clean          Uninstall components and delete cluster"

ensure-tools:
	@command -v kind >/dev/null 2>&1 || { echo "[ERR] kind not found. Install: https://kind.sigs.k8s.io/"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found. Install: https://kubernetes.io/docs/tasks/tools/"; exit 1; }

ensure-helm:
	@command -v helm >/dev/null 2>&1 || { echo "[ERR] helm not found. Install: https://helm.sh/docs/intro/install/"; exit 1; }

create: ensure-tools
	@echo "[INFO] Creating kind cluster: $(CLUSTER_NAME)"
	kind create cluster \
		--name $(CLUSTER_NAME) \
		--config $(KIND_CONFIG) \
		--image $(KIND_NODE_IMAGE)
	@$(MAKE) status

delete: ensure-tools
	@echo "[INFO] Deleting kind cluster: $(CLUSTER_NAME)"
	kind delete cluster --name $(CLUSTER_NAME)

status: ensure-tools
	@echo "[INFO] kubectl context: kind-$(CLUSTER_NAME)"
	kubectl --context kind-$(CLUSTER_NAME) cluster-info

kubectx:
	@echo kind-$(CLUSTER_NAME)

load: ensure-tools
	@if [ -z "$(IMAGE)" ]; then echo "[ERR] Set IMAGE, e.g. make load IMAGE=repo:tag"; exit 1; fi
	@echo "[INFO] Loading image '$(IMAGE)' into cluster '$(CLUSTER_NAME)'"
	kind load docker-image --name $(CLUSTER_NAME) $(IMAGE)
	@$(MAKE) wait-metrics

metrics: ensure-tools ensure-helm
	@$(MAKE) -C components/metrics install CLUSTER_NAME=$(CLUSTER_NAME)

istio: ensure-tools
	@$(MAKE) -C components/istio install CLUSTER_NAME=$(CLUSTER_NAME) ISTIO_PROFILE=$(ISTIO_PROFILE) ISTIO_VERSION=$(ISTIO_VERSION)

gateway: ensure-tools
	@$(MAKE) -C components/gateway install CLUSTER_NAME=$(CLUSTER_NAME)

consul: ensure-tools ensure-helm
	@$(MAKE) -C components/consul install CLUSTER_NAME=$(CLUSTER_NAME)

kiali: ensure-tools ensure-helm
	@$(MAKE) -C components/kiali install CLUSTER_NAME=$(CLUSTER_NAME)

traffic: ensure-tools
	@$(MAKE) -C components/traffic-gen install CLUSTER_NAME=$(CLUSTER_NAME)

traffic-local:
	@echo "[TRAFFIC] Starting local traffic generator (Ctrl+C to stop)"
	BASE_URL=$${BASE_URL:-http://localhost:28080} \
	PATHS=$${PATHS:-catalog/catalogs,order/orders} \
	INTERVAL_MS=$${INTERVAL_MS:-1000} \
	CONCURRENCY=$${CONCURRENCY:-1} \
	JWT_SECRET=$${JWT_SECRET:-replace-with-a-strong-secret-32-bytes-min} \
	USER_ID=$${USER_ID:-test} \
	node components/traffic-gen/local.js

metallb: ensure-tools ensure-helm
	@$(MAKE) -C components/metallb install CLUSTER_NAME=$(CLUSTER_NAME) IP_RANGE=$(IP_RANGE)

proxy:
	@$(MAKE) -C components/proxy-nginx up

all: create metrics proxy istio gateway consul kiali

clean:
	@echo "[CLEAN] Uninstalling components and deleting cluster '$(CLUSTER_NAME)'"
	@$(MAKE) -C components/metrics uninstall CLUSTER_NAME=$(CLUSTER_NAME) || true
	@$(MAKE) -C components/istio uninstall CLUSTER_NAME=$(CLUSTER_NAME) ISTIO_VERSION=$(ISTIO_VERSION) || true
	@$(MAKE) -C components/consul uninstall CLUSTER_NAME=$(CLUSTER_NAME) || true
	@$(MAKE) -C components/gateway clean CLUSTER_NAME=$(CLUSTER_NAME) || true
	@$(MAKE) -C components/proxy-nginx down || true
	@$(MAKE) delete || true
