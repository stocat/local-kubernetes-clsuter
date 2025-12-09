# Redis (Bitnami Helm)

도커 컴포즈의 `stock-redis` 구성을 비트나미 Redis 차트(standalone 모드)로 배포합니다.  
append-only 설정과 5Gi 볼륨, 비밀번호 비활성화 등 compose와 동일한 옵션을 `values.yaml`에 담았습니다.

## 사용법

```bash
# 설치 / 업그레이드
make install

# 템플릿 확인
make template

# 삭제
make uninstall
```

> 기본 네임스페이스는 `data`이며, Istio 자동 주입을 막기 위해 `istio-injection=disabled` 라벨을 붙입니다. 필요하면 Make 변수로 덮어쓰세요.

## 포트 포워딩

```bash
kubectl -n data port-forward svc/redis-master 6380:6379
```
