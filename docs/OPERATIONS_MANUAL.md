# SBOM Dashboard 서비스 운영 매뉴얼

## 목차

1. [시스템 개요](#1-시스템-개요)
2. [시스템 요구사항](#2-시스템-요구사항)
3. [개발 환경 설정](#3-개발-환경-설정)
4. [서버 운영](#4-서버-운영)
5. [Docker 운영](#5-docker-운영)
6. [프로덕션 배포](#6-프로덕션-배포)
7. [데이터베이스 관리](#7-데이터베이스-관리)
8. [백그라운드 작업](#8-백그라운드-작업)
9. [모니터링 및 로깅](#9-모니터링-및-로깅)
10. [트러블슈팅](#10-트러블슈팅)
11. [백업 및 복구](#11-백업-및-복구)
12. [보안 가이드](#12-보안-가이드)

---

## 1. 시스템 개요

### 1.1 서비스 설명

SBOM Dashboard는 소프트웨어 구성 요소 분석(SBOM) 및 취약점 스캔을 위한 웹 애플리케이션입니다.

### 1.2 기술 스택

| 구성 요소 | 기술 | 버전 |
|----------|------|------|
| Framework | Ruby on Rails | 8.0.3 |
| Language | Ruby | 3.4.5 |
| Database | PostgreSQL | 16 |
| Cache/Queue | Redis | 7 |
| Background Jobs | Sidekiq / Solid Queue | - |
| Web Server | Puma + Thruster | - |
| CSS | Tailwind CSS | 4.x |
| JavaScript | Hotwire (Turbo + Stimulus) | - |
| 취약점 스캐너 | Trivy | latest |
| 배포 | Kamal | - |

### 1.3 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                        Client (Browser)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Thruster (HTTP Proxy)                     │
│                    - SSL 종료                                │
│                    - Asset 캐싱                              │
│                    - Gzip 압축                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Puma (Web Server)                       │
│                    - Rails Application                       │
└─────────────────────────────────────────────────────────────┘
           │                  │                    │
           ▼                  ▼                    ▼
    ┌───────────┐      ┌───────────┐        ┌───────────┐
    │ PostgreSQL│      │   Redis   │        │   Trivy   │
    │    (DB)   │      │  (Cache)  │        │ (Scanner) │
    └───────────┘      └───────────┘        └───────────┘
```

---

## 2. 시스템 요구사항

### 2.1 개발 환경

| 항목 | 최소 요구사항 |
|------|--------------|
| OS | macOS, Linux, Windows (WSL2) |
| Ruby | 3.4.5 |
| Node.js | 20.19.0 |
| Yarn | 1.22.22 |
| PostgreSQL | 16.x |
| Redis | 7.x |
| Docker | 24.x (선택) |

### 2.2 프로덕션 환경

| 항목 | 최소 요구사항 | 권장 |
|------|--------------|------|
| CPU | 2 cores | 4+ cores |
| RAM | 2GB | 4GB+ |
| Storage | 20GB | 50GB+ |
| OS | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |

---

## 3. 개발 환경 설정

### 3.1 사전 준비

```bash
# Ruby 설치 (rbenv 사용)
brew install rbenv ruby-build
rbenv install 3.4.5
rbenv global 3.4.5

# Node.js 설치 (nodenv 사용)
brew install nodenv node-build
nodenv install 20.19.0
nodenv global 20.19.0

# Yarn 설치
npm install -g yarn

# PostgreSQL 설치
brew install postgresql@16
brew services start postgresql@16
```

### 3.2 프로젝트 설정

```bash
# 저장소 클론
git clone <repository-url>
cd dashboard_ui

# 의존성 설치
bundle install
yarn install

# 환경 변수 설정
cp .env.example .env.local
# .env.local 파일 수정

# 데이터베이스 설정
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # 선택: 샘플 데이터
```

### 3.3 Docker 기반 의존성 실행

```bash
# PostgreSQL, Redis, Trivy 실행
docker-compose up -d

# 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f
```

### 3.4 개발 서버 실행

```bash
# 전체 개발 서버 실행 (Rails + CSS + JS 빌드)
bin/dev

# 또는 개별 실행
bin/rails server           # Rails 서버만
yarn build --watch         # JavaScript 빌드
yarn build:css --watch     # CSS 빌드
```

### 3.5 접속 정보

| 서비스 | URL | 비고 |
|--------|-----|------|
| 웹 애플리케이션 | http://localhost:3000 | Rails 서버 |
| PostgreSQL | localhost:5432 | DB: sbom_dashboard_development |
| Redis | localhost:6379 | - |
| Trivy Server | http://localhost:8080 | 취약점 스캐너 |

---

## 4. 서버 운영

### 4.1 서버 시작

```bash
# 개발 환경
bin/dev

# 또는 프로덕션 모드로 로컬 실행
RAILS_ENV=production bin/rails server
```

### 4.2 서버 중지

```bash
# PID로 중지
kill $(cat tmp/pids/server.pid)

# 또는 포트로 찾아서 중지
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill

# 강제 종료
kill -9 $(lsof -t -i:3000)
```

### 4.3 서버 재시작

```bash
# 서버 중지 후 시작
bin/rails restart

# 또는
kill -USR2 $(cat tmp/pids/server.pid)  # Graceful restart
```

### 4.4 Rails 콘솔

```bash
# 개발 환경
bin/rails console

# 프로덕션 환경
RAILS_ENV=production bin/rails console

# 샌드박스 모드 (변경사항 롤백)
bin/rails console --sandbox
```

### 4.5 프로세스 상태 확인

```bash
# Rails 서버 프로세스 확인
ps aux | grep puma

# 포트 사용 확인
lsof -i :3000
netstat -tlnp | grep 3000

# 메모리 사용량
ps -o pid,rss,command -p $(pgrep -f puma)
```

---

## 5. Docker 운영

### 5.1 Docker Compose 서비스

```bash
# 모든 서비스 시작
docker-compose up -d

# 특정 서비스만 시작
docker-compose up -d db redis

# 서비스 중지
docker-compose down

# 볼륨 포함 삭제 (데이터 삭제됨!)
docker-compose down -v
```

### 5.2 서비스 상태 확인

```bash
# 컨테이너 상태
docker-compose ps

# 리소스 사용량
docker stats

# 헬스체크 상태
docker inspect --format='{{.State.Health.Status}}' sbom_dashboard_db
```

### 5.3 로그 확인

```bash
# 모든 서비스 로그
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f db
docker-compose logs -f redis
docker-compose logs -f trivy

# 최근 100줄만
docker-compose logs --tail=100 db
```

### 5.4 컨테이너 접속

```bash
# PostgreSQL 접속
docker exec -it sbom_dashboard_db psql -U sbom_dashboard -d sbom_dashboard_development

# Redis CLI
docker exec -it sbom_dashboard_redis redis-cli

# Trivy 컨테이너 쉘
docker exec -it sbom_dashboard_trivy sh
```

### 5.5 Docker 이미지 빌드 (프로덕션)

```bash
# 프로덕션 이미지 빌드
docker build -t sbom-dashboard:latest .

# 빌드된 이미지 실행
docker run -d \
  -p 80:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL=postgres://user:pass@host:5432/dbname \
  --name sbom-dashboard \
  sbom-dashboard:latest
```

---

## 6. 프로덕션 배포

### 6.1 Kamal 배포 설정

`config/deploy.yml` 수정:

```yaml
service: dashboard_ui
image: your-dockerhub-user/dashboard_ui

servers:
  web:
    - your-server-ip

proxy:
  ssl: true
  host: your-domain.com

registry:
  username: your-dockerhub-user
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - DASHBOARD_UI_DATABASE_PASSWORD
  clear:
    SOLID_QUEUE_IN_PUMA: true
    DB_HOST: your-db-host
```

### 6.2 시크릿 설정

`.kamal/secrets` 파일:

```bash
KAMAL_REGISTRY_PASSWORD=your-docker-registry-password
RAILS_MASTER_KEY=$(cat config/master.key)
DASHBOARD_UI_DATABASE_PASSWORD=your-db-password
```

### 6.3 배포 명령어

```bash
# 첫 배포 (서버 설정 포함)
bin/kamal setup

# 일반 배포
bin/kamal deploy

# 롤백
bin/kamal rollback

# 앱 재시작
bin/kamal app restart

# 서버 로그 확인
bin/kamal logs

# Rails 콘솔 접속
bin/kamal console

# 서버 쉘 접속
bin/kamal shell
```

### 6.4 무중단 배포

Kamal은 기본적으로 무중단 배포를 지원합니다:

1. 새 컨테이너 시작
2. 헬스체크 통과 대기
3. 트래픽 전환
4. 이전 컨테이너 종료

### 6.5 환경 변수 관리

```bash
# 환경 변수 확인
bin/kamal env show

# 환경 변수 업데이트 후 재시작
bin/kamal env push
bin/kamal app restart
```

---

## 7. 데이터베이스 관리

### 7.1 마이그레이션

```bash
# 마이그레이션 실행
bin/rails db:migrate

# 마이그레이션 롤백
bin/rails db:rollback
bin/rails db:rollback STEP=3  # 3단계 롤백

# 마이그레이션 상태 확인
bin/rails db:migrate:status

# 프로덕션 마이그레이션
RAILS_ENV=production bin/rails db:migrate
```

### 7.2 데이터베이스 콘솔

```bash
# Rails DB 콘솔
bin/rails dbconsole

# 직접 PostgreSQL 접속
psql -h localhost -U sbom_dashboard -d sbom_dashboard_development
```

### 7.3 데이터베이스 초기화

```bash
# 개발 환경 재설정 (주의: 데이터 삭제!)
bin/rails db:reset

# 스키마만 로드 (마이그레이션 건너뜀)
bin/rails db:schema:load

# 시드 데이터 로드
bin/rails db:seed
```

### 7.4 백업 및 복원

```bash
# 백업
pg_dump -h localhost -U sbom_dashboard sbom_dashboard_production > backup_$(date +%Y%m%d_%H%M%S).sql

# 복원
psql -h localhost -U sbom_dashboard sbom_dashboard_production < backup_20240112_120000.sql

# Docker 환경에서 백업
docker exec sbom_dashboard_db pg_dump -U sbom_dashboard sbom_dashboard_development > backup.sql
```

### 7.5 인덱스 관리

```bash
# 사용되지 않는 인덱스 확인 (PostgreSQL)
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## 8. 백그라운드 작업

### 8.1 Solid Queue (Rails 8 기본)

```bash
# Puma와 함께 실행 (기본 설정)
# SOLID_QUEUE_IN_PUMA=true 환경변수로 활성화됨

# 별도 프로세스로 실행
bin/rails solid_queue:start

# 작업 상태 확인
bin/rails solid_queue:status
```

### 8.2 Sidekiq (대안)

```bash
# Sidekiq 시작
bundle exec sidekiq

# 설정 파일 지정
bundle exec sidekiq -C config/sidekiq.yml

# Sidekiq 웹 UI
# config/routes.rb에 마운트 필요
# mount Sidekiq::Web => '/sidekiq'
```

### 8.3 작업 관리

```bash
# Rails 콘솔에서 작업 확인
ScanJob.perform_later(project_id: 1)

# 예약 작업 확인
Sidekiq::ScheduledSet.new.size
Sidekiq::RetrySet.new.size
```

---

## 9. 모니터링 및 로깅

### 9.1 로그 파일 위치

| 환경 | 위치 |
|------|------|
| 개발 | `log/development.log` |
| 테스트 | `log/test.log` |
| 프로덕션 | `log/production.log` |

### 9.2 로그 확인

```bash
# 실시간 로그 확인
tail -f log/development.log

# 에러만 필터링
grep -i error log/production.log

# 최근 로그
tail -n 1000 log/production.log

# 로그 로테이션 설정 확인
cat /etc/logrotate.d/rails
```

### 9.3 로그 레벨 설정

```ruby
# config/environments/production.rb
config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
```

환경 변수로 런타임 변경:

```bash
RAILS_LOG_LEVEL=debug bin/rails server
```

### 9.4 헬스체크

```bash
# 애플리케이션 헬스체크
curl http://localhost:3000/up

# 데이터베이스 연결 확인
bin/rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"

# Redis 연결 확인
bin/rails runner "Redis.new.ping"
```

### 9.5 성능 모니터링

```bash
# 메모리 사용량
ps -o pid,rss,vsz,command -p $(pgrep -f puma)

# 데이터베이스 연결 수
bin/rails runner "puts ActiveRecord::Base.connection_pool.stat"
```

---

## 10. 트러블슈팅

### 10.1 서버가 시작되지 않음

```bash
# 기존 서버 프로세스 확인 및 종료
lsof -i :3000
kill -9 $(lsof -t -i:3000)

# PID 파일 삭제
rm tmp/pids/server.pid

# 캐시 클리어
bin/rails tmp:clear
```

### 10.2 데이터베이스 연결 오류

```bash
# PostgreSQL 서비스 상태 확인
brew services list | grep postgresql
# 또는
systemctl status postgresql

# 연결 테스트
psql -h localhost -U sbom_dashboard -d sbom_dashboard_development -c "SELECT 1"

# Docker 환경
docker-compose ps db
docker-compose logs db
```

### 10.3 Asset 관련 오류

```bash
# Asset 재컴파일
bin/rails assets:clobber
bin/rails assets:precompile

# JavaScript/CSS 재빌드
yarn build
yarn build:css

# Node 모듈 재설치
rm -rf node_modules
yarn install
```

### 10.4 Gem 관련 오류

```bash
# Bundler 캐시 클리어
bundle clean --force

# Gem 재설치
rm Gemfile.lock
bundle install

# 네이티브 익스텐션 재빌드
bundle pristine
```

### 10.5 마이그레이션 충돌

```bash
# 마이그레이션 상태 확인
bin/rails db:migrate:status

# 특정 버전으로 마이그레이션
bin/rails db:migrate VERSION=20240112000000

# 스키마 덤프 재생성
bin/rails db:schema:dump
```

### 10.6 Redis 연결 오류

```bash
# Redis 서비스 확인
redis-cli ping

# Docker 환경
docker-compose exec redis redis-cli ping

# 연결 정보 확인
bin/rails runner "puts Redis.new.info"
```

---

## 11. 백업 및 복구

### 11.1 자동 백업 스크립트

`scripts/backup.sh`:

```bash
#!/bin/bash
set -e

BACKUP_DIR="/path/to/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="sbom_dashboard_production"
DB_USER="sbom_dashboard"

# 디렉토리 생성
mkdir -p $BACKUP_DIR

# 데이터베이스 백업
pg_dump -h localhost -U $DB_USER $DB_NAME | gzip > $BACKUP_DIR/db_$TIMESTAMP.sql.gz

# Storage 백업
tar -czf $BACKUP_DIR/storage_$TIMESTAMP.tar.gz storage/

# 30일 이상 된 백업 삭제
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completed: $TIMESTAMP"
```

### 11.2 Cron 설정

```bash
# crontab -e
# 매일 새벽 3시 백업
0 3 * * * /path/to/scripts/backup.sh >> /var/log/backup.log 2>&1
```

### 11.3 복구 절차

```bash
# 1. 데이터베이스 복구
gunzip -c backup_20240112_030000.sql.gz | psql -h localhost -U sbom_dashboard sbom_dashboard_production

# 2. Storage 복구
tar -xzf storage_20240112_030000.tar.gz -C /rails/

# 3. 서비스 재시작
bin/kamal app restart
```

---

## 12. 보안 가이드

### 12.1 Credentials 관리

```bash
# Credentials 편집
EDITOR="code --wait" bin/rails credentials:edit

# 프로덕션 Credentials
EDITOR="code --wait" bin/rails credentials:edit --environment production

# Master Key는 절대 커밋하지 말 것
# config/master.key는 .gitignore에 포함됨
```

### 12.2 환경 변수

민감한 정보는 환경 변수로 관리:

```bash
# .env.local (커밋하지 않음)
DATABASE_URL=postgres://user:pass@localhost/db
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=your-secret-key
```

### 12.3 보안 스캔

```bash
# Brakeman (정적 분석)
bin/brakeman

# Bundle Audit (Gem 취약점)
bundle audit check --update

# 의존성 업데이트
bundle update --conservative
```

### 12.4 SSL/TLS 설정

Kamal + Let's Encrypt 자동 설정:

```yaml
# config/deploy.yml
proxy:
  ssl: true
  host: your-domain.com
```

### 12.5 방화벽 설정

```bash
# 필수 포트만 개방
# 80: HTTP (리다이렉트용)
# 443: HTTPS
# 22: SSH (관리용)

sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 12.6 정기 보안 점검

| 항목 | 주기 | 명령어 |
|------|------|--------|
| Gem 취약점 검사 | 주 1회 | `bundle audit` |
| 정적 분석 | 배포 시 | `bin/brakeman` |
| 의존성 업데이트 | 월 1회 | `bundle update` |
| 로그 감사 | 주 1회 | 수동 검토 |

---

## 부록

### A. 유용한 명령어 모음

```bash
# 서버 관리
bin/dev                          # 개발 서버 시작
bin/rails server                 # Rails만 시작
bin/rails console                # 콘솔 접속
bin/rails dbconsole              # DB 콘솔 접속

# 데이터베이스
bin/rails db:migrate             # 마이그레이션 실행
bin/rails db:rollback            # 롤백
bin/rails db:seed                # 시드 데이터
bin/rails db:reset               # DB 초기화

# Asset
bin/rails assets:precompile      # Asset 컴파일
bin/rails assets:clobber         # Asset 삭제
yarn build                       # JS 빌드
yarn build:css                   # CSS 빌드

# 테스트
bin/rails test                   # 테스트 실행
bin/rails test:system            # 시스템 테스트
bundle exec rspec                # RSpec

# 배포 (Kamal)
bin/kamal deploy                 # 배포
bin/kamal rollback               # 롤백
bin/kamal logs                   # 로그
bin/kamal console                # 콘솔
bin/kamal shell                  # 쉘
```

### B. 연락처

| 역할 | 담당 | 연락처 |
|------|------|--------|
| 개발팀 | - | dev@example.com |
| 운영팀 | - | ops@example.com |
| 보안팀 | - | security@example.com |

### C. 변경 이력

| 날짜 | 버전 | 내용 |
|------|------|------|
| 2026-01-12 | 1.0 | 최초 작성 |

---

*본 문서는 SBOM Dashboard 서비스의 운영을 위한 가이드입니다. 문의사항이 있으시면 개발팀에 연락해 주세요.*
