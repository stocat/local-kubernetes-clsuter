# Local Kubernetes with kind + Istio (Gateway API)

이 저장소는 kind 기반 로컬 쿠버네티스 클러스터를 손쉽게 구성하고, Istio + Gateway API, metrics-server, 외부 NGINX 프록시까지 자동화합니다.

핵심 포인트
- Istio를 기본 Ingress로 사용 (Gateway API: Gateway/HTTPRoute)
- 프록시 NGINX가 호스트 20080/20443 → 클러스터 NodePort 32080/32443로 TCP 패스스루
- 사이드카 자동 주입: 클러스터 전역 기본 주입(새 네임스페이스 자동 적용), 필요 시 제외 라벨/애노테이션으로 옵트아웃
- k9s 메트릭 확인을 위한 공식 metrics-server Helm 차트 사용

사전 요구사항
- Docker (데몬 실행 중)
- kind, kubectl, helm
- (필요시) curl

빠른 시작
1) 클러스터 + Istio + metrics 설치 + 외부 NGINX 프록시 실행 (20080/20443 수신) + 게이트웨이 적용
- `make all`
2) 샘플 테스트
  1) 샘플 앱 실행
  - `make -C components/gateway app`
  - `curl -v http://localhost:20080`

디렉토리 구조
- `config/kind-config.yaml`: kind 클러스터 설정 (NodePort 32080/32443 노출)
- `components/`
  - `istio/` — Istio 설치 및 네임스페이스 포함/제외: see `components/istio/README.md`
  - `metrics/` — metrics-server 설치: see `components/metrics/README.md`
  - `proxy-nginx/` — 외부 프록시: see `components/proxy-nginx/README.md`
  - `gateway/` — Gateway/HTTPRoute 샘플: see `components/gateway/README.md`
  - `mysql/` — docker-compose MySQL을 그대로 옮긴 커스텀 Helm 차트
  - `redis/` — Bitnami Redis 차트 래퍼 (docker-compose Redis 대체)

주요 Make 타깃
- 클러스터
  - `make create` / `make delete` / `make status`
  - 최신 노드 이미지: `KIND_NODE_IMAGE ?= kindest/node:v1.34.0`
- Istio
  - `make istio`: Istio 설치 + Gateway API 활성화 + ingressgateway NodePort(32080/32443) 설정 + default NS 라벨 + 전체 NS 라벨(옵션 1)
  - istioctl 버전 고정 사용: 항상 `bin/istioctl`(ISTIO_VERSION)로 실행하며, 지정 버전이 없으면 기본값으로 내려받아 사용
- Metrics
  - `make metrics`: 공식 metrics-server 차트 설치(values.yaml 적용)
- Gateway
  - `make gateway`: Gateway API 활성화 + `Gateway(20080)` + ingressgateway NodePort(32080/32443) 설정
- 데이터 스토어
  - `make mysql`: 커스텀 MySQL 차트 (도커 컴포즈 설정과 동일)
  - `make redis`: Bitnami Redis 차트 (도커 컴포즈 Redis 대체)
- Proxy
  - `make proxy`: 외부 NGINX 20080/20443 리스닝 → 32080/32443 패스스루
- 정리
  - `make clean`: 컴포넌트 언인스톨, 프록시 다운, 클러스터 삭제

사이드카 자동 주입 정책
- 전역 기본 주입을 활성화했습니다: Istio 설치 시 `enableNamespacesByDefault=true`
- 새로 생성되는 네임스페이스는 별도 작업 없이 자동으로 사이드카가 주입됩니다.
- 제외 방법
  - 네임스페이스 라벨: `istio-injection=disabled`
  - 파드 애노테이션: `sidecar.istio.io/inject: "false"`
- 이미 실행 중인 파드는 재시작해야 주입/미주입 정책이 반영됩니다:
  - `kubectl -n <ns> rollout restart deploy/<name>`

Gateway API
- 이 구성은 Gateway API v1.1.0 CRD를 설치하고, Istio Pilot에서 Gateway API를 활성화합니다.
- 기본 샘플은 포트 기반(20080) HTTP 라우팅이며, 외부 접근은 `http://localhost:20080`입니다.
- TLS(SNI) 기반 라우팅도 추가 가능. 필요 시 Gateway 리스너 20443 + 인증서 Secret 예제를 추가하세요.

외부 NGINX 프록시
- 20080/20443 포트를 리슨하고, 클러스터 NodePort 32080/32443로 TCP 패스스루합니다.
- 도메인/호스트 조작 없이 포트만으로 라우팅을 구분하고 싶을 때 유용합니다.

팁/문제해결
- k9s 메트릭 미표시 → metrics-server가 준비 상태인지 확인: `kubectl -n kube-system get deploy metrics-server`
- istio-ingressgateway 포트가 없다고 나오면, `make istio`에서 노출 작업이 완료됐는지 확인
- Helm/다운로드는 네트워크 연결이 필요합니다.

라이선스
- 개인 로컬 개발 환경을 위한 템플릿 수준의 구성입니다. 필요에 따라 자유롭게 수정하세요.
