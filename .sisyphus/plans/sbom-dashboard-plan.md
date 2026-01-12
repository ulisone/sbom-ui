# SBOM Dashboard Web Service - Work Plan

## 프로젝트 개요

**프로젝트명**: SBOM Dashboard
**목적**: SBOM(Software Bill of Materials) 생성 및 취약점 검색 대시보드 웹서비스
**생성일**: 2026-01-12

---

## 기술 스택

| 구성요소 | 기술 |
|----------|------|
| Backend | Ruby on Rails 7.x |
| Frontend | Hotwire (Turbo + Stimulus) |
| CSS | Tailwind CSS (다크모드) |
| Database | PostgreSQL |
| Authentication | Devise |
| Container | Docker / Docker Compose |
| Vulnerability Scanner | Trivy (Docker) |
| SBOM Formats | CycloneDX, SPDX |

---

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Turbo     │  │  Stimulus   │  │  Tailwind (Dark)    │  │
│  │   Frames    │  │  Controllers│  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Ruby on Rails                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Controllers │  │   Models    │  │    Services         │  │
│  │             │  │             │  │  ┌───────────────┐  │  │
│  │ - Projects  │  │ - User      │  │  │ SbomGenerator │  │  │
│  │ - Scans     │  │ - Project   │  │  │ (CycloneDX/   │  │  │
│  │ - Dashboard │  │ - Scan      │  │  │  SPDX)        │  │  │
│  │             │  │ - Vuln      │  │  └───────────────┘  │  │
│  │             │  │             │  │  ┌───────────────┐  │  │
│  │             │  │             │  │  │ ScannerAdapter│  │  │
│  │             │  │             │  │  │ (Strategy)    │  │  │
│  └─────────────┘  └─────────────┘  │  └───────────────┘  │  │
│                                     └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────┐
│      PostgreSQL         │     │    Trivy (Docker Container) │
│  ┌───────────────────┐  │     │                             │
│  │ users             │  │     │  ┌───────────────────────┐  │
│  │ projects          │  │     │  │ aquasec/trivy:latest  │  │
│  │ scans             │  │     │  └───────────────────────┘  │
│  │ vulnerabilities   │  │     │                             │
│  │ dependencies      │  │     │  Future: Snyk, OSV, etc.    │
│  └───────────────────┘  │     └─────────────────────────────┘
└─────────────────────────┘
```

---

## 데이터베이스 스키마

### ERD

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    users     │       │   projects   │       │    scans     │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id           │──────<│ id           │──────<│ id           │
│ email        │       │ user_id (FK) │       │ project_id   │
│ password     │       │ name         │       │ status       │
│ created_at   │       │ description  │       │ sbom_format  │
│ updated_at   │       │ created_at   │       │ sbom_content │
└──────────────┘       │ updated_at   │       │ scanned_at   │
                       └──────────────┘       │ created_at   │
                                              └──────────────┘
                                                     │
                       ┌──────────────┐              │
                       │dependencies  │              │
                       ├──────────────┤              │
                       │ id           │<─────────────┤
                       │ scan_id (FK) │              │
                       │ name         │              │
                       │ version      │              │
                       │ ecosystem    │              │
                       │ purl         │              │
                       └──────────────┘              │
                                                     │
                       ┌──────────────┐              │
                       │vulnerabilities│             │
                       ├──────────────┤              │
                       │ id           │<─────────────┘
                       │ scan_id (FK) │
                       │ cve_id       │
                       │ severity     │
                       │ package_name │
                       │ description  │
                       │ fixed_version│
                       └──────────────┘
```

---

## MVP 기능 명세

### 1. 사용자 인증 (Devise)
- 회원가입 / 로그인 / 로그아웃
- 비밀번호 재설정
- 세션 관리

### 2. 프로젝트 관리
- 프로젝트 생성/수정/삭제
- 프로젝트 목록 조회
- 프로젝트별 스캔 이력

### 3. SBOM 생성
- 의존성 파일 업로드 지원:
  - `package.json`, `package-lock.json` (npm)
  - `requirements.txt`, `Pipfile.lock` (Python)
  - `Gemfile.lock` (Ruby)
  - `pom.xml`, `build.gradle` (Java)
  - `go.mod`, `go.sum` (Go)
- SBOM 형식 선택: CycloneDX / SPDX
- SBOM JSON 저장 및 다운로드

### 4. 취약점 스캔
- Trivy Docker 컨테이너 연동
- Adapter Pattern으로 다른 스캐너 확장 가능
- 취약점 정보 파싱 및 저장

### 5. 대시보드
- 전체 취약점 통계 (Critical/High/Medium/Low)
- 프로젝트별 취약점 현황
- 최근 스캔 목록
- 취약점 상세 정보

---

## 구현 단계

### Phase 1: 프로젝트 초기 설정 (Day 1)

#### 1.1 Rails 프로젝트 생성
```bash
rails new sbom_dashboard --database=postgresql --css=tailwind --javascript=esbuild
```

#### 1.2 Docker 환경 구성
- `Dockerfile` 생성
- `docker-compose.yml` 생성 (Rails + PostgreSQL + Trivy)

#### 1.3 기본 Gem 설정
```ruby
# Gemfile
gem 'devise'              # 인증
gem 'turbo-rails'         # Hotwire Turbo
gem 'stimulus-rails'      # Hotwire Stimulus
gem 'tailwindcss-rails'   # Tailwind CSS
gem 'sidekiq'             # Background jobs
gem 'redis'               # Sidekiq backend
```

#### 1.4 다크모드 Tailwind 설정
- `tailwind.config.js` 다크모드 설정
- 기본 레이아웃 템플릿

---

### Phase 2: 인증 시스템 (Day 2)

#### 2.1 Devise 설정
```bash
rails generate devise:install
rails generate devise User
```

#### 2.2 사용자 UI
- 로그인 페이지 (다크모드)
- 회원가입 페이지
- 비밀번호 재설정

---

### Phase 3: 핵심 모델 구현 (Day 3)

#### 3.1 모델 생성
```bash
rails generate model Project name:string description:text user:references
rails generate model Scan project:references status:string sbom_format:string sbom_content:jsonb scanned_at:datetime
rails generate model Dependency scan:references name:string version:string ecosystem:string purl:string
rails generate model Vulnerability scan:references cve_id:string severity:string package_name:string description:text fixed_version:string
```

#### 3.2 모델 관계 설정
- User has_many Projects
- Project has_many Scans
- Scan has_many Dependencies
- Scan has_many Vulnerabilities

---

### Phase 4: SBOM 생성 서비스 (Day 4-5)

#### 4.1 의존성 파서 구현
```
app/services/parsers/
├── base_parser.rb
├── npm_parser.rb
├── python_parser.rb
├── ruby_parser.rb
├── java_parser.rb
└── go_parser.rb
```

#### 4.2 SBOM 생성기 구현
```
app/services/sbom/
├── base_generator.rb
├── cyclonedx_generator.rb
└── spdx_generator.rb
```

---

### Phase 5: 취약점 스캐너 연동 (Day 6-7)

#### 5.1 Scanner Adapter Pattern
```
app/services/scanners/
├── base_scanner.rb
├── trivy_scanner.rb
└── (future: snyk_scanner.rb, osv_scanner.rb)
```

#### 5.2 Trivy Docker 연동
- Docker API로 Trivy 컨테이너 실행
- SBOM 파일 마운트
- 결과 JSON 파싱

#### 5.3 Background Job
- Sidekiq으로 비동기 스캔 처리
- 스캔 상태 업데이트 (pending → scanning → completed/failed)

---

### Phase 6: 대시보드 UI (Day 8-10)

#### 6.1 레이아웃
```
app/views/layouts/
├── application.html.erb  (다크모드 기본)
├── _navbar.html.erb
└── _sidebar.html.erb
```

#### 6.2 대시보드 페이지
```
app/views/dashboard/
├── index.html.erb        # 메인 대시보드
├── _stats_cards.html.erb # 통계 카드
├── _recent_scans.html.erb
└── _vulnerability_chart.html.erb
```

#### 6.3 프로젝트 페이지
```
app/views/projects/
├── index.html.erb
├── show.html.erb
├── new.html.erb
└── _form.html.erb
```

#### 6.4 스캔 페이지
```
app/views/scans/
├── index.html.erb
├── show.html.erb
├── new.html.erb         # 파일 업로드 폼
└── _vulnerability_list.html.erb
```

#### 6.5 Stimulus Controllers
```
app/javascript/controllers/
├── theme_controller.js      # 다크모드 토글
├── upload_controller.js     # 파일 업로드
├── scan_status_controller.js # 스캔 상태 폴링
└── chart_controller.js      # 차트 렌더링
```

---

### Phase 7: 테스트 및 마무리 (Day 11-12)

#### 7.1 테스트
- Model 테스트
- Service 테스트
- System 테스트 (Capybara)

#### 7.2 문서화
- README.md
- API 문서 (향후 확장용)

#### 7.3 배포 준비
- Production Docker 설정
- 환경 변수 설정

---

## 추후 구현 기능 (Post-MVP)

### Phase 8: Git 저장소 스캔
- Git URL 입력 → 클론 → 스캔
- GitHub/GitLab 연동

### Phase 9: 보고서 내보내기
- PDF 보고서 생성
- JSON 내보내기
- CSV 내보내기

### Phase 10: 팀/조직 기능
- 조직 생성
- 팀 멤버 초대
- 권한 관리

### Phase 11: 추가 스캐너 연동
- Snyk API 연동
- OSV.dev 연동
- GitHub Advisory API 연동

---

## 디렉토리 구조

```
sbom_dashboard/
├── app/
│   ├── controllers/
│   │   ├── dashboard_controller.rb
│   │   ├── projects_controller.rb
│   │   └── scans_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── project.rb
│   │   ├── scan.rb
│   │   ├── dependency.rb
│   │   └── vulnerability.rb
│   ├── services/
│   │   ├── parsers/
│   │   ├── sbom/
│   │   └── scanners/
│   ├── jobs/
│   │   └── scan_job.rb
│   ├── views/
│   │   ├── layouts/
│   │   ├── dashboard/
│   │   ├── projects/
│   │   └── scans/
│   └── javascript/
│       └── controllers/
├── config/
├── db/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
└── spec/
```

---

## 리스크 및 고려사항

### 기술적 리스크
1. **Trivy 컨테이너 실행 권한**: Docker-in-Docker 또는 호스트 Docker 소켓 마운트 필요
2. **대용량 파일 처리**: Active Storage 또는 Direct Upload 고려
3. **스캔 시간**: Background Job으로 처리, 타임아웃 설정

### 보안 고려사항
1. 업로드 파일 검증 (악성 파일 방지)
2. 사용자별 데이터 격리
3. API 키 안전한 저장 (credentials.yml.enc)

---

## 성공 기준

- [ ] 사용자가 의존성 파일을 업로드하여 SBOM 생성 가능
- [ ] CycloneDX/SPDX 형식 선택 가능
- [ ] Trivy로 취약점 스캔 성공
- [ ] 대시보드에서 취약점 현황 확인 가능
- [ ] 다크모드 UI 정상 동작
- [ ] Docker Compose로 전체 서비스 실행 가능

---

## 다음 단계

계획이 승인되면:
1. Rails 프로젝트 생성
2. Docker 환경 구성
3. 순차적으로 Phase 구현

**"Create the plan"** 또는 **"계획 승인"**이라고 말씀해 주시면 구현을 시작하겠습니다.
