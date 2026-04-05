# TodoStory — 개발 로드맵

> **목표 출시**: 2026년 5월 초  
> **현재 상태**: 데이터 레이어 완료, UI 미착수  
> **작성일**: 2026-04-04

---

## 현재 완료된 것

| 파일 | 내용 |
|------|------|
| `data/models/task_model.dart` | Task, Subtask, RepeatConfig 모델 |
| `data/models/project_model.dart` | Project 모델 |
| `data/models/user_model.dart` | User 모델 |
| `data/models/google_calendar_credential_model.dart` | 캘린더 OAuth 토큰 모델 |
| `data/repositories/task_repository.dart` | Firestore CRUD + 스트림 + DnD + 반복 완료 WriteBatch |
| `core/theme/app_theme.dart` | DESIGN.md 기반 라이트/다크 ThemeData |
| `core/theme/app_colors.dart` | 색상 토큰 (오늘 그라디언트 포함) |
| `core/theme/app_text_styles.dart` | Plus Jakarta Sans / Fraunces / Geist Mono |
| `core/router/router.dart` | go_router 기본 셋업 |
| `main.dart` | ProviderScope + MaterialApp.router |
| `DESIGN.md` | 디자인 시스템 (MS Todo 벤치마킹 기반) |
| `firestore.rules` | Firestore 보안 규칙 |
| `firestore.indexes.json` | 복합 인덱스 정의 |
| `codemagic.yaml` | CI/CD 파이프라인 |

---

## Phase 1 — Firebase + 인증 (주 1)

목표: 앱을 실행하면 로그인되고 Firestore에 연결된다.

### 수동 작업 (코드 전에 필요)
- [ ] Firebase 프로젝트 생성 + `google-services.json` → `android/app/` 에 추가
- [ ] Firebase Console에서 Authentication 활성화 (Google, Email/Password)
- [ ] `firebase deploy --only firestore:rules,firestore:indexes`

### 코드 작업
- [x] `ProjectRepository` 작성 (`data/repositories/project_repository.dart`)
- [x] `UserRepository` 작성 — `users/{uid}` + `users/{uid}/private/googleCalendar`
- [x] Riverpod providers 작성
  - `authProvider` — `FirebaseAuth.authStateChanges()` 스트림
  - `taskRepositoryProvider` — uid 기반 TaskRepository
  - `projectRepositoryProvider` — uid 기반 ProjectRepository
  - `userRepositoryProvider` — uid 기반 UserRepository
- [x] 로그인 화면 (`features/auth/screens/login_screen.dart`)
  - Google 로그인 버튼
  - Email/Password 로그인 폼
- [x] Router guard — 비로그인 시 `/login`으로 리다이렉트
- [x] 로그인 성공 시 `users/{uid}` 문서 초기화 (없으면 생성)
- [ ] **온보딩 화면** (신규 사용자 첫 실행)
  - Google 이름 자동 사용 (`firebaseUser.displayName`) — 이름 입력 화면 없음
  - 로그인 직후 "Google Tasks에서 가져올까요?" 단일 선택 화면
  - [가져오기] → Import 화면
  - [건너뛰기] → Today 화면 (빈 상태)
  - 재방문 시 표시 안 함 (`users/{uid}.onboardingComplete: bool`)
- [ ] **기본 랜딩 화면: Today** — 로그인 이후 및 매일 앱 실행 시 Today 화면으로 라디닝

---

## Phase 2 — 핵심 태스크 플로우 (주 1~2)

목표: Inbox에서 할일을 추가하고, 체크하고, 삭제할 수 있다.

### 공통 위젯 (`lib/shared/widgets/`)
- [x] `TaskListItem` — 체크박스 + 제목 + 우측 메타 + 별 아이콘
  - 우측 메타 우선순위: startTime > 서브태스크 진행도 > dueDate
  - 완료 시 취소선 + 체크박스 채우기 애니메이션 (200ms)
  - 마감 지난 태스크: dueDate 텍스트 Error 색상
- [x] `CompletedSection` — "완료 N개" 접기/펼치기 위젯
  - 헤더 텍스트: Label 12sp, Regular, Muted `#6E6E73`, 대문자 변환 없음
  - 아이콘: 화살표 (접힘/펼침), 16px, Muted 색상
- [x] `QuickAddBar` — 하단 고정 입력 바 + 아이콘 행 (기한, 알림, 반복)
  - 높이: 56px. 배경: Surface `#FFFFFF`. 상단 Divider: `#E5E5EA` 1px.
  - 텍스트 입력: Body 14sp, Placeholder Muted `#6E6E73`
  - 아이콘 행: 24px 아이콘, accent `#4E7EFF` (활성 시), Muted (비활성 시)
- [x] `UndoSnackbar` — 3초 Undo 스낵바 (완료/삭제/이동)

### 홈 화면 (`features/home/`)
- [x] `HomeScreen` — Scaffold + Drawer + 탭/뷰 전환
- [x] `AppDrawer` — 프로필, Inbox/Today/Upcoming, 프로젝트 목록, Trash, Settings
- [x] `InboxView` — projectId == null 태스크 목록 (DnD Phase 2 후반)
- [x] `TodayView` — isFocused or dueDate==오늘 + 시간대별 그라디언트 헤더
- [x] `UpcomingView` — dueDate 있는 태스크, 날짜별 섹션 그룹핑

### 태스크 상세 (`features/task_detail/`)
- [x] `TaskDetailSheet` — DraggableScrollableSheet
  - 제목 인라인 편집
  - "단계 추가" (서브태스크)
  - 액션 카드 순서 (이용 빈도 높은 순): 기한(DatePicker) / 오늘 할 일 토글 / 알림 / 반복
  - 메모 입력
  - 하단: 생성일 + 삭제 버튼

### DnD 정렬
- [x] Inbox 뷰 DnD → `order` 필드만 수정
- [x] Today 뷰 DnD → `focusOrder` 필드만 수정
- [x] 리밸런싱 트리거 (gap < 1e-10) 자동 실행
- [ ] 리밸런싱 실패 시 snapshot 롤백 (TODOS High)
- [ ] 리밸런싱 중 로딩 오버레이 (TODOS High)

---

## Phase 3 — 프로젝트 (주 2)

목표: 태스크를 프로젝트로 그룹핑할 수 있다.

- [x] 프로젝트 생성 다이얼로그 (이름 + 컬러 선택)
- [x] `ProjectTaskView` — 프로젝트별 태스크 목록
  - AppBar: 프로젝트 컬러 배경 + 흰 타이틀 (MS Todo 패턴)
  - 완료 섹션 접기/펼치기
- [x] 태스크 상세에서 프로젝트 지정/변경
- [x] 프로젝트 더보기 메뉴 (이름 변경, 삭제)
- [x] 드로어에서 프로젝트 DnD 순서 변경
- [x] **Collaboration UI 제거** — project_member/invite 모델 파일만 존재, UI에서 완전 미노출

---

## Phase 4 — 차별화 기능 (주 3)

목표: Google Tasks 이탈 사용자가 넘어올 이유를 만든다.

### Phase 4 구현 전 추가 작업 (plan-eng-review 결정)

- [ ] **`core/utils/repeat_date_calculator.dart` 생성** — 반복 태스크의 다음 기한 계산 로직.
  `completeRepeatTask(task, nextDueDate: ...)` 호출 전 ViewModel에서 사용.
  `RepeatConfig`(frequency, unit, weekDays)를 받아 `DateTime`을 반환하는 순수 함수.
  테스트: `test/core/utils/repeat_date_calculator_test.dart`

- [ ] **`rebalanceOrder` 500개 가드** — `tasks.length > 500` 시 작업 중단.
  `task_repository.dart` `rebalanceOrder()` 시작 전 체크.
  초과 시 호출자에게 `TooManyTasksException` throw → 뷰에서 "할 일을 줄여주세요" 안내.

### Google Tasks 임포트
- [ ] `ImportService` — Google Tasks API → Firestore batch write
  - `importBatch=true` 플래그로 Cloud Function 캘린더 동기화 차단
  - 완료 후 dueDate 태스크 일괄 캘린더 동기화 트리거
- [ ] 임포트 진행 화면 (진행바, N개 가져오는 중, 부분 실패 상태)
- [ ] 임포트 체크포인트 재개 UX (TODOS High)
- [ ] 로그인 후 Google Tasks 임포트 유도 온보딩

### Google Calendar 동기화

```
데이터 흐름 (onTaskWrite Cloud Function)
─────────────────────────────────────────────────────────────────
Flutter App
  │ setDoc / updateDoc (dueDate 변경)
  ▼
Firestore: users/{uid}/tasks/{taskId}
  │ onDocumentWritten 트리거
  ▼
Cloud Function: onTaskWrite
  ├─ importBatch == true? → EXIT (캘린더 동기화 건너뜀)
  ├─ dueDate 없음? → calendarEventId 있으면 DELETE 후 EXIT
  ├─ Admin SDK → users/{uid}/private/googleCalendar (refresh_token 읽기)
  ├─ oauth2Client.setCredentials({refresh_token})
  ├─ [token 만료/권한 취소]? → calendarSyncStatus: 'failed' 기록 → EXIT
  ├─ Google Calendar API
  │   ├─ calendarEventId 없음 → INSERT (새 이벤트)
  │   └─ calendarEventId 있음 → UPDATE
  ├─ 성공 → calendarSyncStatus: 'ok', calendarEventId 저장
  └─ 실패 (3회 retry 후) → calendarSyncStatus: 'failed'
─────────────────────────────────────────────────────────────────
```

- [ ] OAuth 연결 플로우 (Google Sign-In scope 추가)
- [ ] Cloud Function `onTaskWrite` — dueDate 태스크 → Calendar 이벤트 생성/수정/삭제
  - `google-auth-library` + `oauth2Client.setCredentials({refresh_token})` 패턴
  - `users/{uid}/private/googleCalendar` 서브컬렉션에서 Admin SDK로 refresh token 읽기
  - token refresh 실패 (만료/권한 취소) → `calendarSyncStatus: 'failed'` 즉시 기록
  - malformed task doc (dueDate 포맷 오류, null 필드 등) → try-catch + `functions.logger.error`
- [ ] `calendarSyncStatus` 모니터링 → Settings 재시도 UI (TODOS High)
- [ ] 계정 삭제 시 Calendar 이벤트 정리 Cloud Function (TODOS High)
- **런치 전략**: OAuth consent screen 승인(4-6주) 대기 중에는 테스트 계정 100명 모드로 론치. 승인 후 v1.1에서 전체 활성화.

### Galaxy 캘린더 동기화
- [ ] `device_calendar` 패키지로 로컬 캘린더 쓰기
- [ ] 백그라운드 스레드에서 실행 (ANR 방지, TODOS Medium)
- [ ] Settings에서 토글로 on/off

### Timeline 화면 ✓ 완료
- [x] `TimelineScreen` — 완료된 태스크 월별 그룹핑
  - Fraunces 세리프로 월 헤더 (DESIGN.md 차별화 포인트)
  - 완료 태스크 행: 제목 + 날짜 + 프로젝트 컬러 도트
  - cursor-based pagination (`completedAt DESC`)
- [x] Android Share Sheet로 타임라인 공유 (`share_plus`)
  - **공유 형식**: 현재 월 Timeline을 Bitmap으로 렌더링 후 공유 (텍스트+이미지)
  - `RepaintBoundary` + `RenderRepaintBoundary.toImage()` → PNG → Share Sheet
  - 공유 이미지 레이아웃: 월 헤더(Fraunces) + 완료 항목 리스트 + "TodoStory" 앱명 하단 워터마크
- [ ] 월 헤더 진입 애니메이션: `AnimatedOpacity` + `Transform.scale` (0.8→1.0, 200ms easeInOut)

### Project Archive
- [ ] 프로젝트 "완료 (보관)" — 완료 상태로 전환, 삭제는 아님
- [ ] 드로어에 보관된 프로젝트 섹션 추가

---

## Phase 5 — 폴리시 + 출시 준비 (주 4)

### 모바일 특화
- [ ] 홈 위젯 (Today 뷰, 4x2/4x4)
  - Hive/SharedPreferences 캐시 + WorkManager 갱신 (TODOS High)
- [ ] 푸시 알림 — FCM + Cloud Function 스케줄러
  - 마감 리마인더 (N분 전)
  - 일일 요약 (선택)
- [ ] 햅틱 + 완료음

### Settings 화면
- [ ] 섹션 순서 (핵심 기능 먼저): 캘린더 동기화 → 외관 → 알림 → 계정
  - **[캘린더 동기화]** Google Calendar 연결됨/미연결, Galaxy 캘린더 토글, 동기화 실패 오류 배너
  - **[외관]** 다크 모드, 언어, 주 시작일, 시간 형식
  - **[알림]** 마감 리마인더, 일일 요약
  - **[계정]** 로그아웃, 계정 삭제 (2단계 확인)
- [ ] Calendar 동기화 재시도 버튼 (calendarSyncStatus=failed 시 표시)

### 품질 + 모니터링
- [ ] Crashlytics 연동 (TODOS High)
- [ ] Firebase Analytics 이벤트 (TODOS Medium)
- [ ] GCP 캘린더 동기화 오류 알림 (TODOS Medium)

### 수동 작업 (출시 전)
- [ ] Codemagic 대시보드: Keystore 등록
- [ ] Codemagic 대시보드: 환경변수 그룹 등록
- [ ] Play Store 서비스 계정 생성

---

## 긴급 — 지금 당장 해야 할 수동 작업

> **Google OAuth 동의 화면 제출**  
> `https://www.googleapis.com/auth/calendar` 는 제한된 스코프.  
> 구글 검토에 **4-6주** 소요. 5월 출시 목표면 지금 제출해야 함.  
> 필요한 것: 개인정보처리방침 URL, 앱 홈페이지, 데모 영상

---

## 파일 구조 (목표)

```
lib/
  core/
    theme/          ✓ 완료
    router/         ✓ 기본 완료
  data/
    models/         ✓ 완료
    repositories/   ✓ 완료 (task + project + user)
  features/
    auth/           ✓ 로그인 UI 완료
    home/           🔨 골격만 (Phase 2 진행 중)
    task_detail/    ⬜ 미착수
    project/        ⬜ 미착수
    timeline/       ✓ 완료
    archive/        ⬜ 미착수
    settings/       ⬜ 미착수
    import/         ⬜ 미착수
  shared/
    widgets/        🔨 Phase 2 진행 중
    providers/      ✓ 완료 (auth, task/project/user repo providers)
  main.dart         ✓ 완료
```

---

## 의존성 순서

```
Firebase 연결
  └─ AuthProvider
       └─ Repository Providers
            └─ Phase 2 화면들
                 ├─ Phase 3 (Project)
                 └─ Phase 4 (Calendar, Timeline, Import)
                      └─ Phase 5 (Widget, 알림, Settings)
```

Firebase 연결 (`google-services.json`)이 없으면 앱이 시작되지 않는다.  
**Phase 1 수동 작업이 코드 작업의 전제조건이다.**

---

## 테스트 계획 (Test Schedule)

> /plan-eng-review에서 확정된 결정들 — Issue 4

Firebase 연결 전 `fake_cloud_firestore`로 작성 가능한 유닛/위젯 테스트 목록.  
Coverage 기준: **critical path 18개 중 18개 (100%)** 목표.

### `test/data/repositories/task_repository_test.dart`

| 테스트 케이스 | 검증 대상 |
|-------------|---------|
| `create → watchActiveTasks` 스트림에 나타남 | CRUD 기본 |
| `toggleComplete(false→true)` → `completedAt` 설정, 스트림에서 제거 | 완료 토글 |
| `toggleComplete(true→false)` → `completedAt` null, 스트림 복원 | 완료 취소 |
| `softDelete` → `isDeleted=true`, 스트림에서 제거 | 삭제 |
| `restore` → `isDeleted=false`, 스트림 복원 | 복원 |
| `completeRepeatTask` → 원래 task `completed=true` + 새 occurrence 동시 생성 | WriteBatch 원자성 |
| `completeRepeatTask` 실패 시 → 원래 task 상태 변경 없음 | 롤백 |
| `setFocused(true)` → `focusOrder`가 `order` 값으로 초기화 | focusOrder 초기화 |
| `setFocused(false)` → `focusOrder` null로 클리어 | focusOrder 클리어 |
| `rebalanceOrder` 500개 이하 → 균등 간격으로 재분배 | 리밸런스 기본 |
| `rebalanceOrder` 500개 초과 → 배치 분할 처리 | 배치 분할 |
| `rebalanceOrder(useFocusOrder: true)` → `focusOrder` 필드 업데이트 | Today DnD 리밸런스 |

### `test/features/today/today_view_test.dart`

| 테스트 케이스 | 검증 대상 |
|-------------|---------|
| DnD: A↔B 스왑 → `_computeOrder()` 중간값 반환 | 프랙셔널 인덱싱 |
| DnD: gap < 1e-10 → `rebalanceOrder` 트리거 | 리밸런스 조건 |
| `rebalanceOrder` Firestore 실패 → 스냅샷 롤백, 순서 원복 | 실패 롤백 |
| 리밸런스 중 DnD 비활성화 → 완료 후 재활성화 | 로딩 상태 |

### `test/features/task/toggle_complete_test.dart`

| 테스트 케이스 | 검증 대상 |
|-------------|---------|
| 미완료 탭 → 완료 상태 전환 | 기본 완료 |
| 완료 탭 → 미완료 상태 복원 | 완료 취소 |
| 완료 → 미완료 → 완료 연속 탭 → 최종 완료 상태 | 연속 탭 정합성 |

### 실행 방법

```bash
# Firebase 연결 없이 실행 가능 (fake_cloud_firestore 사용)
flutter test test/data/repositories/task_repository_test.dart
flutter test test/features/today/today_view_test.dart
flutter test test/features/task/toggle_complete_test.dart

# 전체 실행
flutter test
```

> **우선순위**: Firebase 연결 전에 `task_repository_test.dart` 먼저 작성. 리포지토리 로직이 가장 복잡하고 버그 위험이 높다.

---

## 인터랙션 상태 (Interaction States)

> /plan-design-review에서 확정된 결정들

### 공통 로딩 상태

모든 Firestore 스트림 뷰: **Skeleton 플레이스홀더** (shimmer 애니메이션, 캐시 데이터 도착 시 150ms 이하로 사라짐). `CircularProgressIndicator` 사용 금지.

### 공통 오류 상태

Firestore 로드 실패 시: 하단 Snackbar "로드 실패. 재시도" + 재시도 버튼. 오프라인 상태 시: 오프라인 배너 (Firestore 내장 오프라인 모드 활용, 캐시 데이터 표시).

### 화면별 빈 상태 (Empty States)

| 화면 | 빈 상태 UI |
|------|-----------|
| **Inbox** | **텍스트 only (일러스트 없음)**: "할 일을 다 담아두세요" (Plus Jakarta Sans, Body, Muted) + [할 일 추가] + [Google Tasks 가져오기] (이중 CTA). QuickAddBar도 동작. |
| **Today** | **텍스트 only**: "오늘 집중할 일을 추가하세요" (Muted) + [Inbox에서 가져오기] CTA. |
| **Upcoming** | **텍스트 only**: "기한이 있는 할 일이 없어요" (Muted) + [할 일에 기한 추가하기] CTA. |
| **Timeline** | **텍스트 only, Fraunces 서체**: "첫 번째 완료가 여기 기록됩니다" + [할 일 시작하기] (Today로 이동). |
| **Archive** | **텍스트 only**: "완료된 프로젝트가 없어요" (Muted). 프로젝트 더보기 메뉴의 "완료 (보관)" 안내. |
| **프로젝트** | **텍스트 only**: "이 프로젝트에 할 일이 없어요" (Muted) + [할 일 추가]. QuickAddBar 동작. |

### Import 화면 상태

| 상태 | UI |
|------|-----|
| 진행 중 | LinearProgressIndicator + "N개 가져오는 중..." |
| 부분 실패 | "N개 완료, M개 실패" + [실패 항목 재시도] + [완료된 것만 사용] |
| 완료 | "N개 할 일을 가져왔습니다 🎉" + [확인] |
| 재개 프롬프트 | "이전 가져오기를 이어할까요?" + [재개] + [취소] |

---

## 접근성 (Accessibility)

> Android TalkBack 기준 최소 요구사항

- **터치 타겟**: 최소 48×48dp (Material Design 기준). 체크박스, 아이콘 버튼, QuickAddBar 아이콘 모두 적용.
- **색상 대비**: 주요 텍스트(`#1C1C1E` on `#F8F8F6`) — 대비비 16:1 ✓. Muted(`#6E6E73` on `#F8F8F6`) — 4.5:1 이상 확인 필요.
- **TalkBack Semantic Labels**: 체크박스 `semanticsLabel: "태스크 완료"`, 완료 상태 변경 시 announcement. 아이콘 버튼 모두 contentDescription 필수.
- **햅틱 피드백**: 체크박스 완료 시 `HapticFeedback.lightImpact()`. 삭제 시 `HapticFeedback.mediumImpact()`. (Phase 5 완료음과 함께 구현)
- **다크 모드 대비**: 다크 모드 Surface(`#2C2C2E`)에서도 동일한 대비비 유지.

---

## 정보 구조 (Information Architecture)

> /plan-design-review에서 확정된 결정들

### 네비게이션 구조: 드로어 (AppDrawer)

하단 탭바 없음. MS Todo 패턴 유지.

```
AppBar: [☰] 현재 화면 이름  [...]
Drawer:
  [아바타] 사용자명
  ──────────────────
  [★] 오늘 할 일
  [리스트] Inbox
  [캘린더] Upcoming
  [시계] Timeline
  [박스] Archive
  ──────────────────
  [+ 새 프로젝트]
  프로젝트명 (컬러 도트)  ← DnD 재정렬
  ...
  ──────────────────
  [휴지통] Trash
  [설정] Settings
```

### 화면별 정보 계층

| 화면 | 1순위 | 2순위 | 3순위 |
|------|-------|-------|-------|
| Inbox | 태스크 리스트 | QuickAddBar | 완료 섹션(접기) |
| Today | 날짜 헤더 + 시간대 그라디언트 | 태스크 리스트(프로젝트명 서브텍스트) | QuickAddBar |
| Upcoming | 날짜 섹션 헤더 | 태스크 행 | 빈 날짜 없음(날짜 있는 태스크만) |
| 태스크 상세 | 제목(대형 인라인편집) | 서브태스크("단계 추가") | 액션카드 행: 기한>오늘>알림>반복 |
| 프로젝트 | 컬러 헤더(프로젝트명) | 태스크 리스트 | 완료 섹션(접기) |
| Timeline | Fraunces 월 헤더 | 완료 태스크 행(제목+날짜+컬러도트) | 공유 버튼(AppBar) |
| Archive | 완료 프로젝트 목록 | 완료율 배지 | 복원 옵션 |
| Settings | 캘린더 동기화 | 외관 | 알림 → 계정 |

## 승인된 목업 (Approved Mockups)

| 화면/섹션 | 목업 경로 | 방향 | 노트 |
|----------|-----------|------|------|
| Inbox (빈 상태 + 활성 상태) | `~/.gstack/projects/todo-app/designs/todostory-screens-20260405/variant-C.png` | Variant C 승인 — 텍스트 only 빈 상태, 심플 체크박스 리스트, 하단 추가 바 | 드로어 네비게이션 사용 (목업의 하단 탭바 무시), 일러스트 제거하고 텍스트 only 빈 상태로 구현 |

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 2 | CLEAR | 6 proposals, 5 accepted, 1 deferred; 4 cross-model tensions resolved |
| Outside Voice | `/codex review` | Independent 2nd opinion | 2 | issues_found | Firebase OK, Timeline done, OAuth pattern added; onTaskWrite trigger confirmed |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 3 | CLEAR | 5 issues fixed (googleTasksId 추가, notes 복사, CF 다이어그램, RepeatDateCalculator 계획, rebalanceOrder 가드); 23 테스트 신규 작성; 1 critical gap (importBatch 누락 CF 테스트) |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR (FULL) | score: 4/10 → 9/10, 10 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | N/A | 소비자 앱 — DX 리뷰 대상 아님 |

**VERDICT:** CEO + ENG + DESIGN CLEARED — Firebase 연결 후 Phase 4 구현 가능.
**CRITICAL GAP:** Cloud Function `onTaskWrite` 구현 시 `importBatch` 누락 시나리오 테스트 작성 필수.
