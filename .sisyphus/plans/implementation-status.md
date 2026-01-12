# SBOM Dashboard - 구현 현황 및 향후 계획

## 현재 구현 완료된 기능 (MVP + Phase 2)

### 1. 인프라 및 환경 설정
- [x] Ruby on Rails 8.0 프로젝트 구조
- [x] Docker Compose 환경 (PostgreSQL, Redis, Trivy)
- [x] Tailwind CSS v4 다크모드 테마
- [x] Hotwire (Turbo + Stimulus) 설정

### 2. 사용자 인증 (Devise)
- [x] 회원가입 / 로그인 / 로그아웃
- [x] 세션 관리
- [x] 인증 필터 (로그인 필수)

### 3. 데이터 모델
- [x] **User**: 사용자 정보
- [x] **Project**: 프로젝트 관리 (이름, 설명, 저장소 URL)
- [x] **Scan**: 스캔 기록 (상태, SBOM 내용, 스캔 시간)
- [x] **Dependency**: 의존성 정보 (이름, 버전, 패키지 타입, PURL)
- [x] **Vulnerability**: 취약점 정보 (CVE ID, 심각도, 설명, 수정 버전)

### 4. 의존성 파서 (8개 패키지 매니저 지원)
- [x] **npm**: package.json, package-lock.json
- [x] **Python**: requirements.txt, Pipfile.lock
- [x] **Ruby**: Gemfile.lock
- [x] **Java**: pom.xml (Maven)
- [x] **Go**: go.mod, go.sum
- [x] **Rust**: Cargo.lock

### 5. SBOM 생성기
- [x] **CycloneDX 1.5** 형식 생성
- [x] **SPDX 2.3** 형식 생성
- [x] Package URL (PURL) 스펙 준수

### 6. 취약점 스캐너
- [x] **Trivy Scanner** 어댑터 (기본 스캐너)
- [x] Adapter Pattern으로 확장 가능한 구조
- [x] BaseScanner 추상 클래스

### 7. 스캔 서비스
- [x] 의존성 파싱 → SBOM 생성 → 취약점 스캔 파이프라인
- [x] 스캔 상태 관리 (pending → processing → completed/failed)
- [x] 에러 처리 및 로깅

### 8. 대시보드 UI
- [x] **Dashboard**: 전체 통계 요약 (프로젝트, 스캔, 취약점 수)
- [x] **Projects**: 프로젝트 목록, 생성, 상세 보기
- [x] **Scans**: 스캔 목록, 새 스캔 생성, 결과 보기
- [x] **Vulnerabilities**: 취약점 목록 (심각도별 필터링)
- [x] 심각도별 배지 (Critical, High, Medium, Low)
- [x] 반응형 레이아웃
- [x] Stimulus 컨트롤러 (드롭다운, 탭, 알림)

### 9. 페이지네이션
- [x] Kaminari gem으로 목록 페이지네이션

### 10. 파일 업로드 (Phase 2 - 완료)
- [x] Active Storage 연동
- [x] Drag & Drop 파일 업로드 UI
- [x] 다중 파일 업로드 지원
- [x] 파일 미리보기 및 삭제
- [x] 지원 파일 형식 검증

### 11. 백그라운드 작업 처리 (Phase 2 - 완료)
- [x] Active Job + Async 어댑터 (개발 환경)
- [x] Sidekiq 설정 (프로덕션 환경)
- [x] ScanJob - 파일 업로드 스캔 처리
- [x] GitScanJob - Git 저장소 스캔 처리
- [x] Turbo Streams 실시간 상태 업데이트
- [x] 스캔 상태 폴링 (WebSocket 대안)

### 12. 취약점 상세 페이지 (Phase 2 - 완료)
- [x] 취약점 상세 정보 표시
- [x] CVSS 점수 시각화
- [x] 수정 가이드 및 명령어 예제
- [x] 참조 링크 목록
- [x] 스캔 컨텍스트 정보

### 13. Git 저장소 연동 (Phase 2 - 완료)
- [x] 프로젝트에 저장소 URL 필드 추가
- [x] GitRepositoryService - 저장소 클론 및 파일 탐색
- [x] 의존성 파일 자동 탐지
- [x] SSH URL → HTTPS URL 자동 변환
- [x] 스캔 소스 선택 UI (파일 업로드 / Git 저장소)

---

## 향후 구현 예정 기능

### Phase 2: 핵심 기능 강화 (완료)

> Phase 2의 핵심 기능들이 모두 구현되었습니다.

#### 2.4 추가 스캐너 연동 (미완료)
- [ ] **Grype** 스캐너 어댑터
- [ ] **OSV (Google)** API 연동
- [ ] **Snyk** API 연동 (선택)
- [ ] 멀티 스캐너 병렬 실행 및 결과 병합

#### 2.5 추가 기능 (미완료)
- [ ] ZIP 아카이브 업로드 및 자동 파싱
- [ ] Webhook을 통한 자동 스캔 트리거
- [ ] Private 저장소 지원 (토큰 인증)

### Phase 3: 분석 및 리포팅

#### 3.1 취약점 분석
- [ ] 취약점 상세 정보 페이지
- [ ] CVSS 점수 표시
- [ ] 공격 벡터 시각화
- [ ] 수정 가이드 및 권장 버전 안내
- [ ] 취약점 히스토리 추적

#### 3.2 의존성 분석
- [ ] 의존성 트리 시각화 (D3.js)
- [ ] 직접/간접 의존성 구분
- [ ] 라이선스 정보 표시
- [ ] 오래된 패키지 경고

#### 3.3 리포트 기능
- [ ] PDF 리포트 생성
- [ ] Excel/CSV 내보내기
- [ ] SBOM 파일 다운로드 (CycloneDX/SPDX)
- [ ] 이메일 리포트 스케줄링

#### 3.4 대시보드 개선
- [ ] 취약점 트렌드 차트 (Chart.js)
- [ ] 프로젝트별 보안 점수
- [ ] 위험도 히트맵
- [ ] 최근 활동 타임라인

### Phase 4: 협업 및 워크플로우

#### 4.1 팀 협업
- [ ] 조직/팀 관리
- [ ] 역할 기반 접근 제어 (RBAC)
- [ ] 프로젝트 공유 및 권한 관리
- [ ] 활동 로그 및 감사 추적

#### 4.2 알림 시스템
- [ ] 이메일 알림 (새 취약점 발견)
- [ ] Slack/Discord 웹훅 연동
- [ ] 알림 설정 커스터마이징
- [ ] 심각도 임계값 설정

#### 4.3 정책 관리
- [ ] 취약점 허용 정책 (Allowlist)
- [ ] 자동 차단 규칙
- [ ] 컴플라이언스 체크리스트
- [ ] SLA 설정 및 추적

### Phase 5: CI/CD 통합

#### 5.1 API 제공
- [ ] RESTful API 엔드포인트
- [ ] API 키 인증
- [ ] Rate limiting
- [ ] Swagger/OpenAPI 문서

#### 5.2 CI/CD 플러그인
- [ ] GitHub Actions 워크플로우 예제
- [ ] GitLab CI 템플릿
- [ ] Jenkins 플러그인
- [ ] CLI 도구

#### 5.3 빌드 게이트
- [ ] PR 검사 자동화
- [ ] 심각도별 빌드 실패 규칙
- [ ] 머지 블로킹 설정

### Phase 6: 고급 기능

#### 6.1 컨테이너 스캔
- [ ] Docker 이미지 스캔
- [ ] Container Registry 연동
- [ ] 베이스 이미지 분석

#### 6.2 코드 스캔
- [ ] 시크릿 탐지
- [ ] SAST 연동
- [ ] 코드 품질 체크

#### 6.3 자동 수정
- [ ] Dependabot 스타일 PR 생성
- [ ] 자동 버전 업데이트 제안
- [ ] 변경 영향도 분석

---

## 기술 부채 및 개선 사항

### 코드 품질
- [ ] RSpec 테스트 커버리지 80% 이상
- [ ] Rubocop 린트 통과
- [ ] API 문서화
- [ ] 코드 리팩토링 및 추출

### 성능 최적화
- [ ] 데이터베이스 인덱스 최적화
- [ ] N+1 쿼리 제거
- [ ] 캐싱 전략 (Redis)
- [ ] 대용량 SBOM 처리 최적화

### 보안 강화
- [ ] CSRF 보호 검증
- [ ] XSS 방지
- [ ] SQL Injection 방지
- [ ] 보안 헤더 설정
- [ ] 비밀번호 정책 강화

### 인프라
- [ ] Kubernetes 배포 매니페스트
- [ ] Helm 차트
- [ ] 모니터링 (Prometheus/Grafana)
- [ ] 로그 수집 (ELK Stack)

---

## 우선순위 권장 (다음 단계)

| 순위 | 기능 | 이유 |
|------|------|------|
| 1 | 추가 스캐너 연동 (Grype/OSV) | 취약점 탐지 정확도 향상 |
| 2 | 의존성 트리 시각화 | 직접/간접 의존성 이해 |
| 3 | PDF/CSV 리포트 | 비즈니스 보고서 용도 |
| 4 | 트렌드 차트 | 보안 개선 추적 |
| 5 | REST API | CI/CD 통합 |
| 6 | Private 저장소 지원 | 기업 환경 지원 |

---

*마지막 업데이트: 2026-01-12*
