.PHONY: up down restart logs ensure-compose clean

ensure-compose:
	@command -v docker >/dev/null 2>&1 || { echo "[ERR] docker not found"; exit 1; }
	@command -v docker compose >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1 || { echo "[ERR] docker compose not found"; exit 1; }

up: ensure-compose
	@echo "[PROXY] Starting external NGINX (80->30080, 443->30443)"
	@if command -v docker compose >/dev/null 2>&1; then \
	  docker compose up -d; \
	else \
	  docker-compose up -d; \
	fi

down: ensure-compose
	@echo "[PROXY] Stopping external NGINX"
	@if command -v docker compose >/dev/null 2>&1; then \
	  docker compose down; \
	else \
	  docker-compose down; \
	fi

restart: down up

logs:
	@docker logs -f k8s-proxy-nginx

clean: down
