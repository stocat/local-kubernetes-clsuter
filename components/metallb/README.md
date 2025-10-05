# MetalLB (optional)

Installs MetalLB to provide `LoadBalancer` support in kind. Configure an address range from the `kind` Docker network.

Usage
- Install chart: `make install`
- Add IP pool (example): `make apply-pool IP_RANGE=172.18.255.200-172.18.255.250`
- Uninstall: `make uninstall`

Find a suitable IP range
- Linux default `kind` network is often `172.18.0.0/16`. Inspect:
  - `docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' kind`
- Choose a small, unused range within that subnet (avoid overlaps): e.g., `172.18.255.200-172.18.255.250`.

After installation
- Services of `type: LoadBalancer` will receive an IP from the pool.
- If you prefer to keep this repo’s NodePort + external-proxy approach for Istio, you don’t need MetalLB.

