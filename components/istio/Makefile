# Istio component Makefile (istioctl-based)

ISTIO_PROFILE     ?= minimal
ISTIO_VERSION     ?= 1.27.1
NAMESPACE         ?= default
ROOT_DIR      := $(abspath $(CURDIR)/../..)
LOCAL_BIN     := $(ROOT_DIR)/bin
ISTIOCTL_LOCAL := $(LOCAL_BIN)/istioctl

.PHONY: install wait uninstall ensure-tools ensure-istioctl clean \
        download-istioctl include-namespace exclude-namespace

ensure-tools:
	@command -v kubectl >/dev/null 2>&1 || { echo "[ERR] kubectl not found"; exit 1; }
	@command -v curl >/dev/null 2>&1 || { echo "[ERR] curl not found"; exit 1; }

ensure-istioctl:
	@mkdir -p "$(LOCAL_BIN)"
	@if [ -x "$(ISTIOCTL_LOCAL)" ]; then \
	  CUR_VER=$$($(ISTIOCTL_LOCAL) version --remote=false --short 2>/dev/null || echo unknown); \
	  if [ "$$CUR_VER" = "$(ISTIO_VERSION)" ]; then \
	    echo "[ISTIO] Using local $(ISTIOCTL_LOCAL) (v$$CUR_VER)"; \
	  else \
	    echo "[ISTIO] Detected local istioctl v$$CUR_VER; need v$(ISTIO_VERSION). Downloading..."; \
	    $(MAKE) download-istioctl; \
	  fi; \
	else \
	  echo "[ISTIO] Local istioctl not found. Downloading v$(ISTIO_VERSION)"; \
	  $(MAKE) download-istioctl; \
	fi

download-istioctl: ensure-tools
	@echo "[ISTIO] Downloading istioctl $(ISTIO_VERSION) locally into $(LOCAL_BIN)"
	mkdir -p "$(LOCAL_BIN)"
	# Use official download script to get the right OS/ARCH
	curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$(ISTIO_VERSION) sh -
	cp -f "istio-$(ISTIO_VERSION)/bin/istioctl" "$(ISTIOCTL_LOCAL)"
	chmod +x "$(ISTIOCTL_LOCAL)"
	rm -rf "istio-$(ISTIO_VERSION)"

install: ensure-tools ensure-istioctl
	@echo "[ISTIO] Context => kind-$(CLUSTER_NAME)"
	kubectl config use-context kind-$(CLUSTER_NAME) >/dev/null
	@echo "[ISTIO] Installing Istio (profile=$(ISTIO_PROFILE))"
	$(ISTIOCTL_LOCAL) install -y \
	  --set profile=$(ISTIO_PROFILE) \
	  --set values.pilot.env.PILOT_ENABLE_GATEWAY_API=true \
	  --set values.sidecarInjectorWebhook.enableNamespacesByDefault=true
	@$(MAKE) wait
	@echo "[ISTIO] Using Gateway API managed gateway only (no istioctl-managed ingressgateway)"

wait: ensure-tools
	@echo "[ISTIO] Waiting for istiod"
	kubectl --context kind-$(CLUSTER_NAME) -n istio-system rollout status deployment/istiod --timeout=240s
	@echo "[ISTIO] Waiting for istio-ingressgateway (if present)"
	kubectl --context kind-$(CLUSTER_NAME) -n istio-system rollout status deployment/istio-ingressgateway --timeout=240s || \
	  echo "[ISTIO] ingressgateway not present for selected profile"

include-namespace: ensure-tools
	@if [ -z "$(NAMESPACE)" ]; then echo "[ERR] set NAMESPACE=<name>"; exit 1; fi
	@echo "[ISTIO] Allow injection by removing exclusion label in '$(NAMESPACE)'"
	kubectl --context kind-$(CLUSTER_NAME) label ns $(NAMESPACE) istio-injection- --overwrite || true

exclude-namespace: ensure-tools
	@if [ -z "$(NAMESPACE)" ]; then echo "[ERR] set NAMESPACE=<name>"; exit 1; fi
	@echo "[ISTIO] Exclude namespace from injection with label 'istio-injection=disabled' in '$(NAMESPACE)'"
	kubectl --context kind-$(CLUSTER_NAME) label ns $(NAMESPACE) istio-injection=disabled --overwrite

uninstall: ensure-tools ensure-istioctl
	@echo "[ISTIO] Uninstalling Istio"
	$(ISTIOCTL_LOCAL) uninstall -y --purge
	kubectl delete namespace istio-system --ignore-not-found

clean: uninstall
	