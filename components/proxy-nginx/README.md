# External NGINX Proxy

Runs a small NGINX container that forwards host 20080/20443 to the cluster NodePorts 32080/32443 via TCP passthrough.

Ports
- Host 20080 -> Cluster NodePort 32080 (HTTP)
- Host 20443 -> Cluster NodePort 32443 (HTTPS; SNI preserved)

Files
- `nginx.conf`: stream proxy config
- `docker-compose.yaml`: container runner mapping ports

Make targets
- Up: `make up`
- Down: `make down`
- Logs: `make logs`

Notes
- On Linux, `host.docker.internal` is mapped to the host gateway via `extra_hosts`.
- Combine with Istio Gateway listeners on 20080/20443.
