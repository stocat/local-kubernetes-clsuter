# MySQL (Custom Helm)

`docker-compose`에서 사용하던 `stock-mysql` 구성을 그대로 쿠버네티스에 배포하기 위한 경량 Helm 차트입니다.  
이미지는 공식 `mysql:8.0`을 사용하고, UTF-8 인코딩/네이티브 인증 플래그 및 동일한 계정 정보를 제공합니다.

## 주요 리소스
- `Secret` : root/user 패스워드와 사용자 DB 정보를 저장
- `Deployment` : 단일 MySQL 인스턴스 (Recreate 전략)
- `PersistentVolumeClaim` : `/var/lib/mysql` 영구 볼륨
- `Service` : ClusterIP 3306 (필요시 포트포워딩으로 호스트 3305 매핑)

## 사용법

```bash
# 설치/업그레이드
make install

# 템플릿 확인
make template

# 삭제
make uninstall
```

환경을 바꾸고 싶으면 `values.yaml`을 수정하거나 `make install VALUES_FILE=...`로 덮어쓰면 됩니다.

### 포트 포워딩 예시

```bash
kubectl -n data port-forward svc/mysql 3305:3306
```
