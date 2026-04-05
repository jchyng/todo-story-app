# TodoStory — Flutter Android App 기획서

> **버전**: v2.0
> **작성일**: 2026-04-03
> **플랫폼**: Android (Flutter)
> **목표 출시**: 2026년 5월 초 (1개월 이내)
> **백엔드**: Firebase (Firestore + Auth + FCM + Cloud Functions)

---

## 1. 제품 개요

### 1.1 한 줄 요약

**"할 일이 짐이 되지 않는, 가볍고 빠른 태스크 관리 앱"**

TodoStory은 태스크 관리를 모바일에 최적화한 앱이다. 루틴, 캘린더, 포커스 타이머, AI 기능을 과감하게 제외하고 **태스크 하나에 집중**한다. 빠른 입력, 직관적인 정렬(DnD), 미니멀한 UI로 사용자가 "생각나는 즉시 기록하고, 오늘 할 일에 집중하는" 경험을 제공한다.

### 1.2 설계 철학

> **"이 기능이 할 일 목록을 또 다른 짐으로 만드는가?" → YES면 하지 않는다.**

**한다 (Do's)**

- 입력 마찰 최소화 — 제목만 입력하면 태스크 생성 완료
- 즉각적 피드백 — 체크 애니메이션, 완료음, 햅틱
- 심리적 안전감 — Undo, Trash로 실수 복구 가능
- 모바일 네이티브 경험 — 위젯, 푸시 알림, 오프라인 대비

**하지 않는다 (Don'ts)**

- 복잡한 분류 체계 (태그, 라벨, 컨텍스트)
- 과도한 알림이나 리마인더 폭탄
- 게이미피케이션 (포인트, 뱃지, 레벨)
- 설정 오버헤드 (기본값만으로 동작)
- 대시보드나 통계 화면

### 1.3 MVP 범위 (Scope)

| 포함 | 제외 (향후 확장) |
|------|-----------------|
| Tasks (Inbox, Today, Upcoming) | Routines (습관 트래커) |
| Projects (태스크 그룹핑) | Calendar (캘린더 뷰) |
| 서브태스크 | Focus Timer |
| 반복 태스크 | AI Copilot |
| 협업/공유 | Important 뷰 |
| 홈 위젯 | Archive 뷰 |
| 푸시 알림 | Achievements |
| 다크 모드 | 오프라인 모드 (향후) |
| Google/Email 로그인 | Apple 로그인 |

---

## 2. 기능 정의서

### 2.1 태스크 관리 (Core)

#### 2.1.1 태스크 CRUD

**생성**

- 인라인 입력 방식: 리스트 하단에 입력 필드가 항상 노출
- 필수 입력은 **제목(title)** 하나뿐
- 입력 후 Enter(키보드 완료) 시 즉시 생성, 입력 필드는 유지되어 연속 입력 가능
- 생성된 태스크는 리스트 최상단에 추가 (최신 순)

**조회**

- 3가지 뷰: Inbox, Today, Upcoming
- **Inbox**: `projectId`가 null인 태스크 (어떤 프로젝트에도 속하지 않은 태스크)
- **Today**: `isFocused == true` 이거나 `dueDate == 오늘`인 태스크 + 오늘 완료한 태스크 (접기 가능)
- **Upcoming**: `dueDate`가 내일 이후인 태스크 (날짜별 그룹핑)

**수정**

- 태스크 탭 → 상세 화면(Bottom Sheet)으로 진입
- 수정 가능 필드: 제목, 메모, 마감일, 반복 설정, 서브태스크, 프로젝트 지정
- 제목은 상세 화면 상단에서 인라인 편집
- 모든 변경은 자동 저장 (Optimistic UI)

**삭제**

- 왼쪽 스와이프 → 삭제 (Trash로 이동, soft delete)
- 상세 화면 하단 "삭제" 버튼
- Trash는 사이드 드로어에서 접근 가능
- Trash 보관 기간: 30일 후 자동 영구 삭제 (Cloud Functions 스케줄러)

**완료**

- 체크박스 탭 → 체크 애니메이션 + 햅틱 피드백 + 완료음
- 완료된 태스크는 리스트 하단 "완료됨" 섹션으로 이동 (접힌 상태 기본)
- "완료됨" 헤더를 탭하면 펼쳐서 완료 목록 확인 가능
- 완료 취소: 완료됨 섹션에서 체크박스 다시 탭

#### 2.1.2 태스크 정렬

- 우선순위, 필터, 자동 정렬 없음
- 사용자가 **Drag & Drop으로 직접 순서 지정**
- 새로 생성된 태스크는 리스트 최상단에 추가
- 정렬 순서는 `order` 필드(double)로 관리, Firestore에 즉시 동기화

**정렬 순서 계산 규칙 (Fractional Indexing)**

- 리스트 최상단에 추가: `order = 첫 번째 아이템.order - 1.0` (첫 아이템이 없으면 `1000.0`)
- A와 B 사이에 삽입: `order = (A.order + B.order) / 2`
- 리스트 최하단에 추가: `order = 마지막 아이템.order + 1.0`
- 정밀도 한계(소수점 15자리) 도달 시: 해당 리스트의 모든 태스크 order를 1.0, 2.0, 3.0... 으로 리밸런싱 (batch write)

#### 2.1.3 서브태스크

- 태스크 상세 화면에서 서브태스크 추가/수정/삭제/완료
- 서브태스크는 체크리스트 형태
- 서브태스크 완료 시 취소선 표시
- 리스트 뷰에서 서브태스크 진행도 표시 (예: "2/5")

#### 2.1.4 반복 태스크

- 지원 주기: 매일, 평일, 주말, 매주, 매월, 매년, 커스텀
- 커스텀: N일/주/월/년 마다 + 요일 선택 (주간 반복 시)
- 반복 태스크 완료 시 다음 회차 태스크를 즉시 자동 생성 (Upcoming 뷰에 표시)
- 상세 화면에서 반복 설정 UI 제공

#### 2.1.5 마감일 & 시간

- 마감일(due date): 날짜 피커로 선택
- 시작 시간(start time): 선택 사항, 시간 피커
- Upcoming 뷰에서 날짜별 그룹핑 표시
- 마감일 지난 태스크(overdue): 마감일 텍스트를 Error 색상으로 표시. Inbox와 Today 뷰 모두에서 보임

#### 2.1.6 Today에 태스크 추가하는 방법

사용자가 태스크를 Today 뷰에 추가하는 경로는 3가지:

1. Today 화면에서 인라인 입력으로 직접 생성 → `isFocused = true`로 자동 설정
2. Inbox/프로젝트에서 태스크 상세 → 마감일을 오늘로 설정
3. Inbox/프로젝트에서 태스크 상세 → "오늘 할 일에 추가" 토글 (`isFocused = true`)

태스크 상세 Bottom Sheet에 "오늘 할 일" 토글 버튼을 속성 행에 추가한다.

#### 2.1.7 Undo 동작

- 범위: 태스크 완료, 삭제, 프로젝트 이동에 대해 Undo 지원
- UI: 하단 Snackbar "실행 취소" 버튼 (3초간 표시)
- 동작: Optimistic UI 롤백 + Firestore 상태 복원
- 3초 내 Undo 안 하면 서버에 확정 저장

**Optimistic UI + Undo 구현 상세:**
1. 사용자 액션 발생 → 이전 상태(snapshot)를 메모리에 보관
2. UI 즉시 업데이트 (낙관적 반영)
3. Firestore에 비동기 쓰기 시작
4. Undo 클릭 시: 메모리 snapshot으로 UI 복원 + Firestore 쓰기를 원래 값으로 덮어쓰기
5. 3초 경과 시: snapshot 폐기
6. Firestore 쓰기 실패 시: UI를 snapshot으로 롤백 + "저장에 실패했습니다" 토스트

#### 2.1.8 태스크 아이템 우측 표시 정보 우선순위

태스크 아이템 행 우측에 하나의 메타 정보만 표시한다. 우선순위:

1. 시작 시간 (`startTime`이 있으면 "14:00" 형태로 표시)
2. 서브태스크 진행도 (subtasks가 있으면 "2/5" 형태)
3. 마감일 (`dueDate`가 있으면 "내일", "4/5" 등 상대/절대 날짜)
4. 없으면 빈 공간

### 2.2 프로젝트 (태스크 그룹핑)

#### 2.2.1 프로젝트 CRUD

- 사이드 드로어에서 프로젝트 목록 표시
- "새 프로젝트" 버튼으로 생성 (이름만 입력)
- 프로젝트 색상 선택 가능 (프리셋 팔레트)
- 프로젝트 이름 변경, 삭제 지원
- 프로젝트 순서 변경 (DnD)

#### 2.2.2 프로젝트별 태스크 뷰

- 사이드 드로어에서 프로젝트 선택 시 해당 프로젝트의 태스크만 표시
- 태스크 상세에서 프로젝트 지정/변경 가능
- 태스크를 프로젝트에 할당: `projectId` 필드에 프로젝트 ID 설정
- 태스크를 Inbox로 이동: `projectId`를 null로 설정

### 2.3 협업/공유

#### 2.3.1 초대 플로우

1. 프로젝트 소유자(Owner)가 초대 링크 생성
2. 역할 선택: Editor(수정 가능) 또는 Viewer(읽기만)
3. 링크 공유 (Android Share Sheet 활용)
4. 수신자가 링크 클릭 → 앱 딥링크로 진입 → 초대 수락
5. 30일 유효기간, 복수 사용 가능

#### 2.3.2 권한 모델

| 역할 | 태스크 추가 | 태스크 수정 | 태스크 삭제 | 멤버 관리 | 프로젝트 삭제 |
|------|:---------:|:---------:|:---------:|:--------:|:-----------:|
| Owner | O | O | O | O | O |
| Editor | O | O | O | X | X |
| Viewer | X | X | X | X | X |

**Firestore Security Rules에서 서버단 강제. 클라이언트에서도 Viewer일 때 입력 필드 비활성화.**

#### 2.3.3 멤버 관리

- 프로젝트 설정에서 멤버 목록 확인
- 멤버 아바타 + 이름 + 역할 표시
- Owner만 초대 링크 생성/해제 가능
- 멤버 본인은 프로젝트 나가기 가능

### 2.4 모바일 특화 기능

#### 2.4.1 홈 위젯

- Today 위젯: 오늘의 태스크 목록 표시
- 위젯에서 직접 체크박스 탭으로 완료 처리
- 위젯 탭 시 앱의 Today 뷰로 이동
- 크기: 4x2, 4x4 두 가지 사이즈

#### 2.4.2 푸시 알림

- 마감일 리마인더: 마감 N분 전 알림 (사용자 설정)
- 일일 요약: 매일 아침 오늘의 태스크 수 알림 (선택)
- 협업 알림: 공유 프로젝트에서 태스크 변경 시 알림
- 알림 탭 시 해당 태스크 상세로 딥링크

#### 2.4.3 햅틱 & 사운드

- 태스크 완료 시: 경쾌한 완료음 + 가벼운 햅틱
- DnD 시작 시: 가벼운 햅틱
- 삭제 시: 짧은 진동

### 2.5 인증

#### 2.5.1 로그인 방식

- Google 소셜 로그인 (Firebase Auth + Google OAuth)
- Email/Password 로그인 (Firebase Auth)
- 비밀번호 재설정 (Firebase Auth 이메일 링크)

#### 2.5.2 세션 관리

- Firebase Auth ID Token 기반
- 자동 토큰 갱신 (Firebase SDK가 자동 처리)
- 로그아웃 시 로컬 데이터 클리어 + Firestore 리스너 해제

#### 2.5.3 앱 생명주기 + 인증 연동

| 상태 전환 | 동작 |
|----------|------|
| 앱 시작 (콜드 스타트) | `FirebaseAuth.authStateChanges()` 구독 → 인증 상태 확인 → 로그인 상태면 Firestore 리스너 시작, 아니면 로그인 화면 |
| 백그라운드 → 포그라운드 | Firestore 리스너는 자동 재연결 (Firebase SDK 내장). 추가로 `AppLifecycleState.resumed`에서 FCM 토큰 갱신 체크 |
| 포그라운드 → 백그라운드 | Firestore 리스너 유지 (Firebase SDK가 자동으로 연결 관리). 홈 위젯 데이터 갱신 |
| 토큰 만료 | Firebase SDK가 자동으로 refresh. `authStateChanges()`에서 null 수신 시 로그인 화면으로 이동 |
| 네트워크 끊김 | Firestore offline persistence 활성화 상태이므로 캐시 데이터로 읽기 가능. 쓰기는 큐에 저장, 재연결 시 자동 동기화 |
| 네트워크 복구 | Firestore가 자동으로 pending writes 동기화. 상단 "오프라인" 배너 제거 |

### 2.6 설정

- 표시 이름 변경
- 다크 모드: 시스템 따라가기 / 라이트 / 다크 수동 전환
- 언어: 한국어, English
- 알림 설정: 푸시 on/off, 리마인더 기본값, 일일 요약 시간
- 주 시작일: 일요일 / 월요일
- 시간 형식: 12시간 / 24시간
- 계정: 로그아웃, 계정 삭제 (Cloud Functions에서 사용자 데이터 전체 삭제, 확인 다이얼로그 2단계)

---

## 3. UI/UX 정의

### 3.1 네비게이션 구조

```
┌─────────────────────────────────┐
│  [=] TodoStory           [+] [...]  │  ← App Bar (햄버거 = 드로어)
├─────────────────────────────────┤
│                                 │
│  ┌─ Side Drawer ─────────────┐  │
│  │                           │  │
│  │  [프로필 영역]             │  │
│  │   이름 / 이메일            │  │
│  │                           │  │
│  │  ─────────────────────    │  │
│  │                           │  │
│  │  📥 Inbox                 │  │
│  │  ☀️ Today                 │  │
│  │  📅 Upcoming              │  │
│  │                           │  │
│  │  ─────────────────────    │  │
│  │                           │  │
│  │  PROJECTS                 │  │
│  │  🔵 프로젝트 A            │  │
│  │  🟢 프로젝트 B            │  │
│  │  🟠 프로젝트 C (공유)     │  │
│  │  + 새 프로젝트             │  │
│  │                           │  │
│  │  ─────────────────────    │  │
│  │                           │  │
│  │  🗑️ Trash                 │  │
│  │  ⚙️ Settings              │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  [메인 콘텐츠 영역]              │
│                                 │
└─────────────────────────────────┘
```

**사이드 드로어 구성**

- 상단: 사용자 프로필 (아바타, 이름, 이메일)
- 기본 뷰: Inbox, Today, Upcoming
- 프로젝트 섹션: 프로젝트 목록 + 새 프로젝트 버튼
- 하단: Trash, Settings

### 3.2 화면별 상세 정의

#### 3.2.1 Inbox 화면 (기본 화면)

```
┌─────────────────────────────────┐
│  [=]  Inbox                     │
├─────────────────────────────────┤
│                                 │
│  ○ 새로 추가한 태스크 3          │
│  ○ 새로 추가한 태스크 2          │
│  ○ 새로 추가한 태스크 1          │
│  ○ 기존 태스크 A                │
│  ○ 기존 태스크 B      3/5       │
│  ○ 기존 태스크 C      내일      │
│                                 │
│  ▸ 완료됨 (3)                   │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  ○  태스크 추가...              │  ← 인라인 입력 (항상 보임)
└─────────────────────────────────┘
```

**동작 설명**

- 리스트는 `order` 필드 기준 오름차순 정렬
- 각 태스크 행: 체크박스 + 제목 + (서브태스크 카운트 or 마감일)
- 태스크 탭 → Bottom Sheet로 상세 열기
- 태스크 롱프레스 → DnD 모드 진입 (햅틱)
- 왼쪽 스와이프 → 삭제 (빨간 배경 + 휴지통 아이콘)
- "완료됨" 섹션: 접힌 상태 기본, 탭하면 펼침
- 하단 인라인 입력: Fixed Bottom으로 키보드 위에 고정, 리스트는 입력 필드 위에서만 스크롤

#### 3.2.2 Today 화면

```
┌─────────────────────────────────┐
│  [=]  Today          4월 3일    │
├─────────────────────────────────┤
│                                 │
│  ○ 오늘 할 태스크 1             │
│  ○ 오늘 할 태스크 2   14:00    │
│  ○ Inbox에서 추가한 것  2/3    │
│                                 │
│  ▸ 완료됨 (2)                   │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  ○  태스크 추가...              │
└─────────────────────────────────┘
```

**동작 설명**

- `isFocused == true`인 태스크 + `dueDate == 오늘`인 태스크
- Today에서 생성한 태스크는 자동으로 `isFocused = true` 설정
- 정렬 기준: `focusOrder` 필드 (double, order와 동일한 fractional indexing)
- 오늘 완료한 태스크는 "완료됨" 섹션에 표시
- 오른쪽에 시작 시간 표시 (있는 경우)
- App Bar 우측에 오늘 날짜 표시

#### 3.2.3 Upcoming 화면

```
┌─────────────────────────────────┐
│  [=]  Upcoming                  │
├─────────────────────────────────┤
│                                 │
│  내일 — 4월 4일 (금)            │
│  ○ 미팅 준비                    │
│  ○ 보고서 마감        15:00    │
│                                 │
│  4월 7일 (월)                   │
│  ○ 주간 리뷰                    │
│                                 │
│  4월 10일 (목)                  │
│  ○ 프로젝트 발표                │
│                                 │
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**동작 설명**

- `dueDate`가 내일 이후인 태스크를 날짜별로 그룹핑
- 날짜 헤더: 요일 + 날짜
- "내일"은 날짜 대신 텍스트로 표시
- 인라인 입력 없음 (Inbox 또는 Today에서 태스크 생성 후 마감일을 설정하면 Upcoming에 자동 표시)

#### 3.2.4 태스크 상세 (Bottom Sheet)

```
┌─────────────────────────────────┐
│  ─── (드래그 핸들)              │
│                                 │
│  ● 프로젝트명              [X]  │
│                                 │
│  ○ 태스크 제목 (편집 가능)       │
│                                 │
│  메모를 입력하세요...            │
│  (여러 줄 텍스트 에디터)         │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  ☀️  오늘 할 일       [토글]    │
│  📅  마감일         4월 5일 >   │
│  🔁  반복           매주 월 >   │
│  📋  프로젝트       Inbox   >   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  서브태스크                      │
│  ☑ 자료 조사                    │
│  ○ 초안 작성                    │
│  ○ 검토 요청                    │
│  + 서브태스크 추가               │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  🗑️ 삭제                        │
│                                 │
└─────────────────────────────────┘
```

**동작 설명**

- Full-screen Bottom Sheet (상단 드래그 핸들)
- 아래로 스와이프하면 닫힘
- 제목: 인라인 편집, 자동 포커스 안됨
- 메모: 멀티라인 텍스트, 플레이스홀더
- 속성 행: 아이콘 + 라벨 + 값, 탭 시 피커 열림
- 서브태스크: 체크리스트, 완료 시 취소선, 추가 버튼
- 하단 삭제 버튼: 확인 다이얼로그 없이 즉시 Trash 이동 (Undo 토스트로 복구)
- 모든 변경 자동 저장 (변경 감지 후 500ms debounce → Firestore 쓰기)

#### 3.2.5 프로젝트 뷰

```
┌─────────────────────────────────┐
│  [<]  프로젝트 A   [👤2] [...]  │
├─────────────────────────────────┤
│                                 │
│  ○ 프로젝트 태스크 1            │
│  ○ 프로젝트 태스크 2    내일    │
│  ○ 프로젝트 태스크 3    2/4    │
│                                 │
│  ▸ 완료됨 (5)                   │
│                                 │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  ○  태스크 추가...              │
└─────────────────────────────────┘
```

**동작 설명**

- App Bar: 뒤로 가기 + 프로젝트명 + 멤버 아이콘(공유 시) + 더보기 메뉴
- 더보기 메뉴: 이름 변경, 색상 변경, 공유 설정, 삭제
- 멤버 아이콘 탭 → 멤버 목록 Bottom Sheet
- 공유 프로젝트에서 다른 멤버가 수정한 태스크: 에디터 아바타 표시

#### 3.2.6 공유 설정 화면

```
┌─────────────────────────────────┐
│  [<]  공유 설정                  │
├─────────────────────────────────┤
│                                 │
│  멤버 (3)                       │
│  ┌─────────────────────────┐    │
│  │ 🟢 나 (Owner)           │    │
│  │ 🔵 김철수 (Editor)      │    │
│  │ 🟠 이영희 (Viewer)      │    │
│  └─────────────────────────┘    │
│                                 │
│  초대 링크                       │
│  ┌─────────────────────────┐    │
│  │ Editor 링크    [복사][X] │    │
│  └─────────────────────────┘    │
│                                 │
│  + 초대 링크 만들기              │
│                                 │
│                                 │
│  [프로젝트 나가기]               │
│                                 │
└─────────────────────────────────┘
```

#### 3.2.7 Settings 화면

```
┌─────────────────────────────────┐
│  [<]  Settings                  │
├─────────────────────────────────┤
│                                 │
│  계정                           │
│  ┌─────────────────────────┐    │
│  │ 표시 이름      홍길동  > │    │
│  │ 이메일    hong@mail.com  │    │
│  └─────────────────────────┘    │
│                                 │
│  일반                           │
│  ┌─────────────────────────┐    │
│  │ 테마         시스템    > │    │
│  │ 언어         한국어    > │    │
│  │ 주 시작일    월요일    > │    │
│  │ 시간 형식    24시간    > │    │
│  └─────────────────────────┘    │
│                                 │
│  알림                           │
│  ┌─────────────────────────┐    │
│  │ 푸시 알림        [토글]  │    │
│  │ 일일 요약        [토글]  │    │
│  │ 요약 시간    오전 8:00 > │    │
│  └─────────────────────────┘    │
│                                 │
│  [로그아웃]                      │
│  [계정 삭제]                     │
│                                 │
└─────────────────────────────────┘
```

#### 3.2.8 Trash 화면

```
┌─────────────────────────────────┐
│  [<]  Trash          [비우기]   │
├─────────────────────────────────┤
│                                 │
│  삭제된 태스크 1       3일 전   │
│  삭제된 태스크 2       5일 전   │
│  삭제된 태스크 3       1주 전   │
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**동작 설명**

- 삭제된 태스크 목록 (`deletedAt != null`, 삭제일 역순)
- 태스크 탭 → 복원 확인 다이얼로그
- "비우기" → 전체 영구 삭제 확인

#### 3.2.9 로그인 화면

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│          TodoStory                   │
│    할 일, 가볍게 기록하세요       │
│                                 │
│                                 │
│  ┌─────────────────────────┐    │
│  │  G  Google로 계속하기    │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  ✉  이메일로 계속하기    │    │
│  └─────────────────────────┘    │
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

### 3.3 화면 전환 플로우

```
[로그인 화면]
    │
    ├── Google 로그인 → [첫 로그인?] → YES → [온보딩: 이름 설정] → [알림 권한 요청] → [Inbox 화면]
    │                                  → NO  → [Inbox 화면]
    └── Email 로그인 →  (동일 플로우)

[Inbox 화면] (기본 진입점)
    │
    ├── 사이드 드로어 열기 (햄버거 or 스와이프)
    │   ├── Today 탭 → [Today 화면]
    │   ├── Upcoming 탭 → [Upcoming 화면]
    │   ├── 프로젝트 탭 → [프로젝트 뷰]
    │   ├── Trash 탭 → [Trash 화면]
    │   └── Settings 탭 → [Settings 화면]
    │
    ├── 태스크 탭 → [태스크 상세 Bottom Sheet]
    │   ├── 프로젝트 변경 → [프로젝트 선택 피커]
    │   ├── 마감일 설정 → [날짜 피커]
    │   ├── 반복 설정 → [반복 설정 Sheet]
    │   └── 아래 스와이프 → [Inbox 화면으로 돌아감]
    │
    ├── 태스크 왼쪽 스와이프 → 삭제 (Undo 토스트)
    ├── 태스크 롱프레스 → DnD 모드
    └── 인라인 입력 → 태스크 즉시 생성

[프로젝트 뷰]
    │
    ├── 더보기 메뉴
    │   ├── 공유 설정 → [공유 설정 화면]
    │   ├── 이름 변경 → [이름 편집 다이얼로그]
    │   └── 삭제 → [확인 다이얼로그]
    │
    └── 멤버 아이콘 → [멤버 목록 Bottom Sheet]

[딥링크 진입]
    │
    ├── /invite/{token} → [초대 수락 화면] → [프로젝트 뷰]
    └── 푸시 알림 탭 → [해당 태스크 상세]
```

### 3.4 마이크로 인터랙션

**태스크 완료**

1. 체크박스 탭
2. 체크 아이콘 스케일 애니메이션 (0 → 1.2 → 1.0, 200ms)
3. 제목에 취소선 페이드 인 (150ms)
4. 햅틱 (light impact)
5. 완료음 재생
6. 300ms 후 태스크가 "완료됨" 섹션으로 슬라이드 다운 (300ms ease-out)

**태스크 삭제 (스와이프)**

1. 왼쪽으로 스와이프 시작
2. 배경 빨간색 노출 + 휴지통 아이콘
3. 임계점(40%) 넘기면 햅틱 + 삭제
4. 태스크 row가 슬라이드 아웃 (200ms)
5. 하단에 "삭제됨 — 실행 취소" 토스트 (3초)

**DnD 재정렬**

1. 롱프레스 (300ms) → 햅틱 (medium impact)
2. 태스크가 살짝 떠오르는 그림자 효과
3. 드래그 중 다른 아이템들이 부드럽게 밀림
4. 드롭 시 가벼운 바운스 + 햅틱 (light)

**인라인 입력**

1. 입력 필드 탭 → 키보드 올라옴
2. 입력 필드가 키보드 위로 자연스럽게 이동
3. 텍스트 입력 후 완료(Enter) → 태스크 생성
4. 새 태스크가 리스트 상단에 슬라이드 인 (200ms)
5. 입력 필드 클리어, 포커스 유지 (연속 입력)

**Bottom Sheet (태스크 상세)**

1. 태스크 탭 → Bottom Sheet 올라옴 (300ms, ease-out)
2. 배경 dimming (50% 블랙)
3. 위로 드래그 → full screen 확장
4. 아래로 드래그 → 닫힘 (velocity 기반 스냅)
5. 배경 탭 → 닫힘

### 3.5 빈 상태 (Empty States)

**Inbox 비어있을 때**

```
      (미니멀 일러스트)

  모든 할 일을 처리했어요!
  아래에서 새 태스크를 추가해보세요.
```

**Today 비어있을 때**

```
      (미니멀 일러스트)

  오늘은 여유로운 하루예요.
  Inbox에서 오늘 할 일을 추가해보세요.
```

**Upcoming 비어있을 때**

```
      (미니멀 일러스트)

  예정된 할 일이 없어요.
  태스크에 마감일을 설정해보세요.
```

### 3.6 에러 & 엣지 케이스

- 네트워크 오류: 상단 배너 "오프라인 상태입니다". Firestore offline persistence 덕분에 캐시 데이터 읽기 가능, 쓰기는 pending queue에 저장 → 재연결 시 자동 동기화
- 동기화 실패: 토스트 "저장에 실패했습니다. 다시 시도해주세요."
- 공유 초대 만료: "초대 링크가 만료되었습니다" 화면
- 공유 프로젝트 삭제됨: "이 프로젝트는 더 이상 존재하지 않습니다"
- 권한 없음 (Viewer가 수정 시도): 입력 필드 비활성화 + 안내 텍스트
- Firestore permission-denied 에러: Optimistic UI 롤백 + "권한이 없습니다" 토스트

---

## 4. 디자인 시스템

### 4.1 개요

Material Design 3 (Material You)를 기반으로 하되, TodoStory의 미니멀하고 깨끗한 톤을 유지한다. M3의 Dynamic Color는 사용하지 않고, 고정된 TodoStory 브랜드 컬러 팔레트를 사용한다.

### 4.2 컬러 시스템

#### Brand Colors

```
Primary:          #0b85f1  (Calm Blue)
On Primary:       #FFFFFF
Primary Container:#D6E8FF
On Primary Cont.: #001B3D
```

#### Light Theme

```
Surface:          #FAFAFA
On Surface:       #1C1B1F
Surface Variant:  #F0F0F0
On Surface Var.:  #6B6B6B
Outline:          #E0E0E0
Outline Variant:  #EEEEEE

Secondary:        #5B6B7A
On Secondary:     #FFFFFF
Tertiary:         #6B5B7A

Error:            #E53935
On Error:         #FFFFFF
Error Container:  #FDECEA

Success:          #2E7D32
Success Container:#E8F5E9

Background:       #FFFFFF
On Background:    #1C1B1F
```

#### Dark Theme

```
Surface:          #121212
On Surface:       #E6E1E5
Surface Variant:  #1E1E1E
On Surface Var.:  #A0A0A0
Outline:          #2C2C2C
Outline Variant:  #1E1E1E

Primary:          #6DB6FF
On Primary:       #00315B
Primary Container:#004A86
On Primary Cont.: #D6E8FF

Error:            #EF9A9A
Error Container:  #3B1C1C

Success:          #81C784
Success Container:#1B3D1C

Background:       #0E0E0E
On Background:    #E6E1E5
```

#### Project Colors (프리셋 팔레트)

```
Blue:    #4A90D9
Green:   #4CAF50
Orange:  #FF9800
Red:     #EF5350
Purple:  #AB47BC
Teal:    #26A69A
Pink:    #EC407A
Indigo:  #5C6BC0
```

### 4.3 타이포그래피

Google Fonts의 **Pretendard** (한국어) + **Inter** (영문)을 사용한다.

| 토큰 | 크기 | 굵기 | 행간 | 용도 |
|------|------|------|------|------|
| Display Large | 32sp | Bold (700) | 40sp | 온보딩 타이틀 |
| Headline Medium | 24sp | SemiBold (600) | 32sp | 화면 타이틀 |
| Title Large | 20sp | SemiBold (600) | 28sp | 섹션 헤더 |
| Title Medium | 16sp | Medium (500) | 24sp | 카드 타이틀, 태스크 제목 |
| Body Large | 16sp | Regular (400) | 24sp | 본문, 메모 |
| Body Medium | 14sp | Regular (400) | 20sp | 보조 텍스트, 메타 정보 |
| Body Small | 12sp | Regular (400) | 16sp | 캡션, 타임스탬프 |
| Label Large | 14sp | Medium (500) | 20sp | 버튼 텍스트 |
| Label Small | 11sp | Medium (500) | 16sp | 배지, 태그 |

### 4.4 스페이싱 & 그리드

8dp 그리드 시스템, 4dp 베이스 유닛.

| 토큰 | 값 | 용도 |
|------|-----|------|
| space-xs | 4dp | 아이콘-텍스트 간격 |
| space-sm | 8dp | 인라인 요소 간격 |
| space-md | 12dp | 리스트 아이템 내부 패딩 |
| space-base | 16dp | 화면 좌우 패딩, 카드 패딩 |
| space-lg | 24dp | 섹션 간격 |
| space-xl | 32dp | 화면 상하 마진 |
| space-2xl | 48dp | 대형 여백 |

### 4.5 Elevation & Shadow

M3 Elevation 시스템을 따른다.

| 레벨 | 용도 |
|------|------|
| Level 0 | Surface (기본 배경) |
| Level 1 | 사이드 드로어, 카드 |
| Level 2 | Bottom Sheet, FAB |
| Level 3 | 드롭다운 메뉴, 스낵바 |

다크 모드에서는 그림자 대신 surface tint(밝기 조절)로 elevation 표현.

### 4.6 Border Radius

| 토큰 | 값 | 용도 |
|------|-----|------|
| radius-xs | 4dp | 체크박스 |
| radius-sm | 8dp | 입력 필드, 작은 버튼 |
| radius-md | 12dp | 카드, 리스트 아이템 |
| radius-lg | 16dp | Bottom Sheet 상단 |
| radius-xl | 28dp | FAB, 대형 버튼 |
| radius-full | 9999dp | 아바타, 원형 아이콘 |

### 4.7 아이콘

**Material Symbols Rounded** 사용 (M3 기본)

| 아이콘 | 용도 |
|--------|------|
| inbox | Inbox 뷰 |
| today | Today 뷰 |
| calendar_month | Upcoming 뷰 |
| folder | 프로젝트 |
| delete | 삭제/Trash |
| settings | 설정 |
| check_circle | 태스크 완료 |
| radio_button_unchecked | 태스크 미완료 |
| drag_indicator | DnD 핸들 |
| add | 추가 버튼 |
| repeat | 반복 |
| event | 마감일 |
| group | 멤버 |
| share | 공유 |
| link | 초대 링크 |
| content_copy | 복사 |
| undo | 실행 취소 |

아이콘 크기: 20dp (리스트), 24dp (App Bar, 버튼)

### 4.8 컴포넌트 토큰

#### 체크박스 (태스크 완료)

```
미완료:
  - 원형 아웃라인 (24dp)
  - Border: 2dp, On Surface Variant 색상
  - 내부: 투명

완료:
  - 원형 채움 (24dp)
  - Background: Primary
  - 체크마크: On Primary (흰색)

탭 영역: 48x48dp (M3 최소 터치 타겟)
```

#### 태스크 아이템

```
높이: 52dp (1줄) / 68dp (서브태스크 카운트 포함)
좌우 패딩: 16dp
체크박스 ↔ 제목 간격: 12dp
배경: Surface
구분선: Outline Variant (하단 1dp)
스와이프 배경: Error (삭제)

터치 피드백: M3 ripple effect
롱프레스: elevation 상승 + 그림자
```

#### 인라인 입력 필드

```
높이: 52dp
좌측: 체크박스 자리 (비활성, 회색 원)
배경: Surface Variant
텍스트: Body Medium, On Surface
플레이스홀더: Body Medium, On Surface Variant
하단 구분선: Primary (포커스 시)
```

#### Bottom Sheet

```
상단 드래그 핸들:
  - 32dp x 4dp
  - Border Radius: full
  - 색상: Outline

상단 radius: radius-lg (16dp)
배경: Surface
Scrim: #000000, 50% opacity
```

#### 사이드 드로어

```
너비: 화면의 80% (최대 304dp)
배경: Surface
프로필 영역: 높이 160dp, padding 16dp
메뉴 아이템: 높이 48dp, 아이콘 24dp + 텍스트
선택 상태: Primary Container 배경
```

### 4.9 모션

Flutter의 Material 3 motion system 활용.

| 전환 | 애니메이션 | Duration | Curve |
|------|----------|----------|-------|
| 화면 전환 | Shared axis (horizontal) | 300ms | Easing.emphasized |
| Bottom Sheet 열기 | Slide up + fade | 300ms | Easing.emphasizedDecelerate |
| Bottom Sheet 닫기 | Slide down + fade | 250ms | Easing.emphasizedAccelerate |
| 태스크 완료 | Scale + fade out | 500ms | Easing.standard |
| 태스크 삭제 (스와이프) | Slide out left | 200ms | Easing.standard |
| DnD 시작 | Scale up (1.02x) + shadow | 150ms | Easing.standard |
| 리스트 아이템 추가 | Slide in from top + fade | 200ms | Easing.emphasizedDecelerate |
| 토스트 | Slide up + fade | 200ms | Easing.standard |
| 드로어 열기 | Slide from left | 250ms | Easing.emphasized |

### 4.10 접근성

- 최소 터치 타겟: 48x48dp (M3 권장)
- 색상 대비: WCAG AA (4.5:1) 이상
- 스크린 리더: Semantics 위젯 적용 (모든 인터랙티브 요소)
- 텍스트 크기 조절: 시스템 폰트 크기 설정 반영 (sp 단위)
- 동작 줄이기: 시스템 "애니메이션 줄이기" 설정 시 모션 비활성화

---

## 5. 기술 아키텍처

### 5.1 기술 스택

| 카테고리 | 기술 | 비고 |
|---------|------|------|
| 프레임워크 | Flutter 3.x | Dart |
| 상태 관리 | Riverpod 2.x | AsyncNotifier 패턴 |
| 백엔드 DB | Cloud Firestore | NoSQL, 실시간 동기화 |
| 인증 | Firebase Auth | Google OAuth + Email/Password |
| 푸시 알림 | Firebase Cloud Messaging (FCM) | 서버 → 클라이언트 알림 |
| 서버 로직 | Cloud Functions (2nd gen, Dart 또는 TypeScript) | 초대 수락, 스케줄 작업, 계정 삭제 |
| DnD | Flutter 기본 `ReorderableListView.builder` | 스와이프 삭제는 `Dismissible` 위젯 |
| 위젯 | home_widget | Android 홈 위젯 |
| 딥링크 | go_router + Firebase Dynamic Links | 초대 링크 처리 |
| 애니메이션 | Flutter built-in | implicit/explicit animations |
| 아이콘 | material_symbols_icons | M3 아이콘 |
| 폰트 | google_fonts | Pretendard + Inter |
| 다국어 | flutter_localizations + intl | ARB 파일 기반 |
| 오프라인 | Firestore offline persistence | enablePersistence (기본 활성) |
| 사운드 | audioplayers | 완료음 재생 |
| 햅틱 | HapticFeedback (Flutter services) | 기본 제공 |

### 5.2 프로젝트 구조

```
lib/
├── main.dart
├── app.dart                    # MaterialApp, 테마, 라우팅, Firebase 초기화
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart      # Light/Dark ThemeData 정의
│   │   ├── colors.dart         # 컬러 토큰 (AppColors 클래스)
│   │   ├── typography.dart     # 타이포 토큰 (AppTypography 클래스)
│   │   └── spacing.dart        # 스페이싱 토큰 (AppSpacing 클래스)
│   ├── router/
│   │   └── app_router.dart     # go_router 설정 + 인증 가드
│   ├── constants/
│   │   └── app_constants.dart  # Firestore collection names, 기본값 등
│   ├── l10n/
│   │   ├── app_ko.arb          # 한국어 번역
│   │   └── app_en.arb          # 영어 번역
│   └── utils/
│       ├── date_utils.dart     # 날짜 포맷, 상대 날짜 ("내일", "3일 전")
│       ├── order_utils.dart    # Fractional indexing 계산 유틸
│       └── debouncer.dart      # Debounce 유틸 (자동 저장용)
│
├── data/
│   ├── models/
│   │   ├── task_model.dart           # Task 데이터 모델
│   │   ├── project_model.dart        # Project 모델
│   │   ├── subtask_model.dart        # Subtask 모델
│   │   ├── project_member_model.dart # ProjectMember 모델
│   │   ├── project_invite_model.dart # ProjectInvite 모델
│   │   └── user_settings_model.dart  # UserSettings 모델
│   └── repositories/
│       ├── task_repository.dart      # Firestore tasks CRUD + 실시간 스트림
│       ├── project_repository.dart   # Firestore projects CRUD + 실시간 스트림
│       ├── auth_repository.dart      # Firebase Auth 래퍼
│       ├── user_repository.dart      # Firestore users 프로필/설정
│       └── invite_repository.dart    # Cloud Functions 호출 (초대 수락)
│
├── providers/
│   ├── auth_provider.dart            # 인증 상태 (AsyncNotifier)
│   ├── task_list_provider.dart       # 뷰별 태스크 목록 (필터링 + 정렬)
│   ├── task_detail_provider.dart     # 단일 태스크 상세 (편집 상태)
│   ├── project_list_provider.dart    # 프로젝트 목록
│   ├── project_detail_provider.dart  # 단일 프로젝트 (멤버, 초대)
│   ├── settings_provider.dart        # 사용자 설정
│   └── theme_provider.dart           # 테마 모드 (system/light/dark)
│
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── email_login_screen.dart
│   │   ├── email_signup_screen.dart
│   │   └── onboarding_screen.dart
│   ├── tasks/
│   │   ├── inbox_screen.dart
│   │   ├── today_screen.dart
│   │   ├── upcoming_screen.dart
│   │   ├── trash_screen.dart
│   │   └── widgets/
│   │       ├── task_item.dart           # 단일 태스크 행
│   │       ├── task_list.dart           # Reorderable + Dismissible 리스트
│   │       ├── task_detail_sheet.dart   # 상세 Bottom Sheet
│   │       ├── inline_task_input.dart   # 하단 인라인 입력
│   │       ├── completed_section.dart   # 접기/펼치기 완료 섹션
│   │       ├── date_picker_sheet.dart   # 날짜 피커 + 단축 칩
│   │       ├── repeat_picker_sheet.dart # 반복 설정 Sheet
│   │       └── project_picker_sheet.dart # 프로젝트 선택 Sheet
│   ├── projects/
│   │   ├── project_screen.dart
│   │   ├── share_settings_screen.dart
│   │   └── widgets/
│   │       ├── member_list_sheet.dart
│   │       └── color_picker_sheet.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   └── invite/
│       └── invite_screen.dart
│
├── widgets/
│   ├── app_drawer.dart         # 사이드 드로어
│   ├── empty_state.dart        # 빈 상태 위젯
│   ├── undo_snackbar.dart      # Undo 토스트
│   ├── offline_banner.dart     # 오프라인 배너
│   └── loading_indicator.dart
│
└── services/
    ├── notification_service.dart  # FCM 초기화 + 토큰 관리
    ├── haptic_service.dart        # 햅틱 피드백 래퍼
    ├── sound_service.dart         # 완료음 재생
    └── widget_service.dart        # 홈 위젯 데이터 업데이트
```

### 5.3 상태 관리 아키텍처 (Riverpod)

#### Provider 구조도

```
[Firebase Auth Stream]
    │
    ▼
authStateProvider (StreamProvider<User?>)
    │
    ├── currentUserProvider (Provider<User>)  — null이면 로그인 화면
    │
    ├──▶ taskStreamProvider (StreamProvider<List<Task>>)
    │       Firestore 'users/{uid}/tasks' 컬렉션 실시간 구독
    │       deleted_at == null 필터
    │       │
    │       ├── inboxTasksProvider (Provider<List<Task>>)
    │       │     projectId == null, completed == false, order 정렬
    │       │
    │       ├── todayTasksProvider (Provider<List<Task>>)
    │       │     (isFocused == true || dueDate == today) && completed == false
    │       │     focusOrder 정렬
    │       │
    │       ├── upcomingTasksProvider (Provider<List<Task>>)
    │       │     dueDate > today && completed == false
    │       │     dueDate 정렬 → 날짜별 그룹핑
    │       │
    │       ├── completedTodayProvider (Provider<List<Task>>)
    │       │     completed == true && completedAt이 오늘
    │       │
    │       ├── completedByProjectProvider (Provider.family<List<Task>, String?>)
    │       │     completed == true && 최근 7일 && projectId 일치
    │       │
    │       └── trashTasksProvider (Provider<List<Task>>)
    │             별도 스트림: deleted_at != null, 삭제일 역순
    │
    ├──▶ projectStreamProvider (StreamProvider<List<Project>>)
    │       Firestore 'projects' 컬렉션 (멤버 기반 쿼리)
    │       │
    │       └── projectTasksProvider (Provider.family<List<Task>, String>)
    │             projectId == 해당 프로젝트, completed == false
    │
    ├──▶ settingsProvider (AsyncNotifierProvider<SettingsNotifier, UserSettings>)
    │       Firestore 'users/{uid}' 문서의 settings 필드
    │
    └──▶ themeProvider (NotifierProvider<ThemeNotifier, ThemeMode>)
            settingsProvider.darkMode에서 파생
```

#### 핵심 규칙

1. **Repository는 순수 Firestore 래퍼**: Stream 반환, CRUD 메서드만 제공. 비즈니스 로직 없음
2. **StreamProvider로 실시간 데이터 구독**: Firestore snapshots → Dart 모델 변환
3. **필터/정렬은 파생 Provider에서 처리**: `taskStreamProvider`에서 전체 목록을 받고, 뷰별 Provider가 필터링
4. **쓰기 작업은 Repository 직접 호출**: Provider를 거치지 않고 `ref.read(taskRepositoryProvider).updateTask(...)` 호출
5. **Optimistic UI는 Provider 레벨에서 처리하지 않음**: Firestore의 실시간 리스너가 즉시 로컬 캐시를 업데이트하므로, 별도 optimistic 로직 불필요 (Firestore offline persistence가 이를 자동 처리)

#### Realtime 동기화 & 충돌 방지

Firestore의 `snapshots()` 스트림은 로컬 쓰기도 즉시 반영(local write → immediate snapshot event)하므로, 자기 자신의 변경과 타인의 변경을 별도로 구분할 필요 없음. Firestore SDK가 다음을 자동 처리:

- 로컬 쓰기 → 로컬 캐시 즉시 반영 → UI 업데이트 (optimistic)
- 서버 확인 → metadata.hasPendingWrites가 false로 변경
- 서버 쓰기 실패 → 로컬 캐시 자동 롤백 → UI 자동 업데이트
- 다른 기기/사용자의 변경 → 서버에서 수신 → 로컬 캐시 업데이트 → UI 반영

**충돌 전략**: Last-Write-Wins. Firestore `update()`는 필드 단위 병합이므로, 서로 다른 필드를 수정하면 충돌 없음. 같은 필드를 동시에 수정하면 마지막 쓰기가 승리.

### 5.4 딥링크 스킴

```
todostory://invite/{token}          → 초대 수락 화면
todostory://task/{taskId}           → 태스크 상세 화면
https://todostory.page.link/invite/{token} → Firebase Dynamic Links → 앱 설치 or 초대 수락
```

### 5.5 DnD + 스와이프 제스처 공존 규칙

`ReorderableListView.builder`와 `Dismissible`을 함께 사용할 때의 제스처 분리:

- **롱프레스 → DnD 시작**: `ReorderableListView`의 기본 동작
- **수평 스와이프 → Dismissible 삭제**: `Dismissible`의 기본 동작
- **충돌 방지**: `Dismissible`의 `direction: DismissDirection.endToStart` (왼쪽 스와이프만)로 제한. DnD는 수직 방향이므로 충돌 없음
- **DnD 중 스와이프 비활성화**: DnD 상태일 때 `Dismissible`의 `confirmDismiss`에서 false 반환
- 구현: 리스트 레벨에서 `isDragging` 상태를 관리, 각 `Dismissible`에 전달

---

## 6. 데이터 모델 & Firestore 스키마

### 6.1 Firestore 컬렉션 구조

```
firestore-root/
│
├── users/{userId}                    # 사용자 프로필 + 설정
│   │   - email: string
│   │   - displayName: string?
│   │   - avatarUrl: string?
│   │   - fcmToken: string?           # 푸시 알림 토큰
│   │   - settings: map (UserSettings)
│   │   - onboarding: map
│   │   - createdAt: timestamp
│   │   - updatedAt: timestamp
│   │
│   └── tasks/{taskId}                # 사용자의 개인 태스크 (서브컬렉션)
│       - title: string
│       - notes: string?
│       - completed: boolean
│       - isFocused: boolean
│       - dueDate: string? ("YYYY-MM-DD")
│       - startTime: string? ("HH:mm")
│       - projectId: string?          # projects 컬렉션의 문서 ID (null = Inbox)
│       - subtasks: array<map>        # [{id, title, completed}]
│       - repeat: string?             # 'daily'|'weekdays'|'weekends'|'weekly'|'monthly'|'yearly'|'custom'
│       - repeatConfig: map?          # {frequency, unit, weekDays?}
│       - order: number               # 리스트 정렬 (fractional indexing)
│       - focusOrder: number?         # Today 뷰 정렬
│       - completedAt: timestamp?
│       - deletedAt: timestamp?       # soft delete (null = 활성)
│       - reminderOffset: number?     # 마감 N분 전 알림
│       - reminderSentAt: timestamp?
│       - createdAt: timestamp
│       - updatedAt: timestamp
│
├── projects/{projectId}              # 프로젝트 (공유 가능)
│   │   - name: string
│   │   - color: string?              # hex 코드
│   │   - ownerId: string             # 생성자 userId
│   │   - memberIds: array<string>    # 멤버 userId 배열 (쿼리용)
│   │   - order: number               # 드로어 정렬
│   │   - createdAt: timestamp
│   │   - updatedAt: timestamp
│   │
│   ├── members/{userId}              # 프로젝트 멤버 (서브컬렉션)
│   │   - role: string                # 'owner'|'editor'|'viewer'
│   │   - displayName: string?
│   │   - avatarUrl: string?
│   │   - joinedAt: timestamp
│   │
│   ├── tasks/{taskId}                # 프로젝트 태스크 (서브컬렉션)
│   │   - (개인 태스크와 동일 필드)
│   │   - createdBy: string           # 생성자 userId
│   │   - lastEditorId: string?       # 마지막 수정자 userId
│   │   - lastEditorName: string?
│   │   - lastEditorAvatarUrl: string?
│   │
│   └── invites/{inviteId}            # 초대 링크 (서브컬렉션)
│       - token: string
│       - role: string                # 'editor'|'viewer'
│       - createdBy: string
│       - expiresAt: timestamp
│       - useCount: number
│       - createdAt: timestamp
│
└── inviteTokens/{token}              # 초대 토큰 → 프로젝트 매핑 (역인덱스)
    - projectId: string
    - inviteId: string
    - role: string
    - expiresAt: timestamp
```

**설계 이유:**

- **개인 태스크 = `users/{uid}/tasks`**: Security Rules에서 owner 기반 접근 제어가 자연스러움
- **프로젝트 태스크 = `projects/{pid}/tasks`**: 멤버 전원이 접근해야 하므로 프로젝트 하위에 배치
- **`memberIds` 배열**: Firestore `array-contains` 쿼리로 "내가 속한 프로젝트" 목록을 효율적으로 조회
- **`inviteTokens` 최상위 컬렉션**: 토큰만으로 어떤 프로젝트인지 찾기 위한 역인덱스

### 6.2 Dart 데이터 모델

```dart
// lib/data/models/task_model.dart
class Task {
  final String id;
  final String title;
  final bool completed;
  final String? notes;
  final String? dueDate;         // "YYYY-MM-DD"
  final String? startTime;       // "HH:mm" (24h)
  final String? projectId;       // null = Inbox
  final List<Subtask> subtasks;
  final bool isFocused;          // Today 뷰 포함 여부
  final String? repeat;          // 'daily'|'weekdays'|'weekends'|'weekly'|'monthly'|'yearly'|'custom'
  final RepeatConfig? repeatConfig;
  final double order;            // fractional indexing (리스트/프로젝트 내 정렬)
  final double? focusOrder;      // Today 뷰 정렬
  final DateTime? completedAt;
  final DateTime? deletedAt;     // null = 활성, non-null = Trash
  final int? reminderOffset;     // 마감 N분 전
  final DateTime? reminderSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // 협업 전용 (프로젝트 태스크일 때만 사용)
  final String? createdBy;
  final String? lastEditorId;
  final String? lastEditorName;
  final String? lastEditorAvatarUrl;

  // Firestore 변환
  factory Task.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore();

  // deletedAt 기반 편의 getter
  bool get isDeleted => deletedAt != null;
}

class Subtask {
  final String id;               // UUID
  final String title;
  final bool completed;
}

class RepeatConfig {
  final int frequency;           // 반복 주기 (예: 2 = 2주마다)
  final String unit;             // 'day'|'week'|'month'|'year'
  final List<int>? weekDays;     // 0(일)~6(토), 주간 반복 시
}

// lib/data/models/project_model.dart
class Project {
  final String id;
  final String name;
  final String? color;           // hex 코드
  final String ownerId;
  final List<String> memberIds;  // 쿼리용
  final double order;            // 드로어 정렬
  final DateTime createdAt;
  final DateTime updatedAt;
  // 조회 시 추가 정보
  final String? currentUserRole; // 현재 사용자의 역할 (join 결과)
  final int memberCount;

  factory Project.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore();
}

// lib/data/models/project_member_model.dart
class ProjectMember {
  final String userId;
  final String role;             // 'owner'|'editor'|'viewer'
  final String? displayName;
  final String? avatarUrl;
  final DateTime joinedAt;
}

// lib/data/models/project_invite_model.dart
class ProjectInvite {
  final String id;
  final String token;
  final String role;             // 'editor'|'viewer'
  final String createdBy;
  final DateTime expiresAt;
  final int useCount;
  final DateTime createdAt;
}

// lib/data/models/user_settings_model.dart
class UserSettings {
  final String themeMode;        // 'system'|'light'|'dark'
  final String language;         // 'en'|'ko'
  final String startOfWeek;      // 'sun'|'mon'
  final String timeFormat;       // '12h'|'24h'
  final bool soundEnabled;
  final bool pushEnabled;
  final bool dailySummaryEnabled;
  final String dailySummaryTime; // "08:00" (HH:mm)

  factory UserSettings.defaults() => UserSettings(
    themeMode: 'system',
    language: 'ko',
    startOfWeek: 'mon',
    timeFormat: '24h',
    soundEnabled: true,
    pushEnabled: true,
    dailySummaryEnabled: true,
    dailySummaryTime: '08:00',
  );
}
```

### 6.3 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ========== 사용자 프로필 ==========
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false; // Cloud Functions에서만 삭제

      // ========== 개인 태스크 ==========
      match /tasks/{taskId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // ========== 프로젝트 ==========
    match /projects/{projectId} {
      // 멤버만 읽기 가능
      allow read: if request.auth != null
        && request.auth.uid in resource.data.memberIds;

      // 생성: 인증된 사용자, 본인이 owner로 포함
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.ownerId
        && request.auth.uid in request.resource.data.memberIds;

      // 수정: owner만 (이름, 색상, order 변경)
      allow update: if request.auth != null
        && request.auth.uid == resource.data.ownerId;

      // 삭제: owner만
      allow delete: if request.auth != null
        && request.auth.uid == resource.data.ownerId;

      // ========== 프로젝트 태스크 ==========
      match /tasks/{taskId} {
        // 멤버 전원 읽기
        allow read: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/projects/$(projectId)).data.memberIds;

        // owner, editor만 쓰기
        allow create, update, delete: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/projects/$(projectId)).data.memberIds
          && getMemberRole(projectId, request.auth.uid) in ['owner', 'editor'];
      }

      // ========== 프로젝트 멤버 ==========
      match /members/{memberId} {
        allow read: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/projects/$(projectId)).data.memberIds;
        allow write: if false; // Cloud Functions에서만 관리
      }

      // ========== 초대 ==========
      match /invites/{inviteId} {
        allow read: if request.auth != null
          && request.auth.uid == get(/databases/$(database)/documents/projects/$(projectId)).data.ownerId;
        allow create: if request.auth != null
          && request.auth.uid == get(/databases/$(database)/documents/projects/$(projectId)).data.ownerId;
        allow delete: if request.auth != null
          && request.auth.uid == get(/databases/$(database)/documents/projects/$(projectId)).data.ownerId;
        allow update: if false; // Cloud Functions에서만 (useCount 증가)
      }
    }

    // ========== 초대 토큰 역인덱스 ==========
    match /inviteTokens/{token} {
      allow read: if request.auth != null; // 토큰으로 프로젝트 찾기
      allow write: if false; // Cloud Functions에서만
    }

    // ========== 헬퍼 함수 ==========
    function getMemberRole(projectId, userId) {
      return get(/databases/$(database)/documents/projects/$(projectId)/members/$(userId)).data.role;
    }
  }
}
```

### 6.4 Firestore 쿼리 명세

#### 개인 태스크 실시간 구독

```dart
// 활성 태스크 (삭제되지 않은 것)
FirebaseFirestore.instance
  .collection('users').doc(uid)
  .collection('tasks')
  .where('deletedAt', isNull: true)
  .orderBy('order')
  .snapshots();

// Trash 태스크
FirebaseFirestore.instance
  .collection('users').doc(uid)
  .collection('tasks')
  .where('deletedAt', isNull: false)
  .orderBy('deletedAt', descending: true)
  .snapshots();
```

#### 프로젝트 목록 (내가 속한 것)

```dart
FirebaseFirestore.instance
  .collection('projects')
  .where('memberIds', arrayContains: uid)
  .orderBy('order')
  .snapshots();
```

#### 프로젝트 태스크

```dart
FirebaseFirestore.instance
  .collection('projects').doc(projectId)
  .collection('tasks')
  .where('deletedAt', isNull: true)
  .orderBy('order')
  .snapshots();
```

#### 태스크 생성 (Inbox)

```dart
await FirebaseFirestore.instance
  .collection('users').doc(uid)
  .collection('tasks')
  .doc(newTaskId) // 클라이언트에서 UUID 생성
  .set({
    'title': title,
    'completed': false,
    'isFocused': isFocused, // Today에서 생성 시 true
    'projectId': null,
    'subtasks': [],
    'order': newOrder, // 리스트 최상단 order 값
    'deletedAt': null,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

#### 태스크 생성 (프로젝트)

```dart
await FirebaseFirestore.instance
  .collection('projects').doc(projectId)
  .collection('tasks')
  .doc(newTaskId)
  .set({
    'title': title,
    'completed': false,
    'isFocused': isFocused,
    'projectId': projectId,
    'subtasks': [],
    'order': newOrder,
    'deletedAt': null,
    'createdBy': uid,
    'lastEditorId': uid,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

#### 태스크 수정

```dart
// 개인 태스크
await FirebaseFirestore.instance
  .collection('users').doc(uid)
  .collection('tasks').doc(taskId)
  .update({
    'title': newTitle,
    // ... 변경된 필드만
    'updatedAt': FieldValue.serverTimestamp(),
  });

// 프로젝트 태스크
await FirebaseFirestore.instance
  .collection('projects').doc(projectId)
  .collection('tasks').doc(taskId)
  .update({
    'title': newTitle,
    'lastEditorId': uid,
    'lastEditorName': currentUserName,
    'lastEditorAvatarUrl': currentUserAvatar,
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

#### 태스크 Soft Delete

```dart
await taskRef.update({
  'deletedAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

#### 태스크 복원 (Trash에서)

```dart
await taskRef.update({
  'deletedAt': null,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

#### 태스크 영구 삭제

```dart
await taskRef.delete();
```

#### 태스크를 프로젝트로 이동 (Inbox → 프로젝트)

```dart
// 1. 개인 태스크 삭제
final taskData = (await personalTaskRef.get()).data()!;
await personalTaskRef.delete();

// 2. 프로젝트 태스크로 생성
await FirebaseFirestore.instance
  .collection('projects').doc(projectId)
  .collection('tasks').doc(taskId)
  .set({
    ...taskData,
    'projectId': projectId,
    'createdBy': uid,
    'lastEditorId': uid,
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

#### 태스크를 Inbox로 이동 (프로젝트 → Inbox)

```dart
// 1. 프로젝트 태스크 삭제
final taskData = (await projectTaskRef.get()).data()!;
await projectTaskRef.delete();

// 2. 개인 태스크로 생성 (협업 필드 제거)
await FirebaseFirestore.instance
  .collection('users').doc(uid)
  .collection('tasks').doc(taskId)
  .set({
    ...taskData,
    'projectId': null,
    'createdBy': null,
    'lastEditorId': null,
    'lastEditorName': null,
    'lastEditorAvatarUrl': null,
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

### 6.5 "완료됨" 섹션 표시 규칙

| 뷰 | 표시 대상 | 필터 조건 |
|----|----------|----------|
| Inbox | 최근 7일 완료된 Inbox 태스크 | `completed == true && projectId == null && completedAt >= 7일 전` |
| Today | 오늘 완료한 태스크만 | `completed == true && completedAt의 날짜 == 오늘` |
| 프로젝트 뷰 | 최근 7일 완료된 해당 프로젝트 태스크 | `completed == true && completedAt >= 7일 전` |
| Upcoming | 표시 안 함 | — |

7일 이상 지난 완료 태스크는 Firestore에 보존되지만 클라이언트에서 필터링하여 표시하지 않음. 향후 Archive 뷰에서 활용.

---

## 7. Cloud Functions 명세

### 7.1 초대 수락 (Callable Function)

```
함수명: acceptInvite
트리거: Callable (클라이언트에서 직접 호출)
입력: { token: string }
동작:
  1. inviteTokens/{token}에서 projectId, role 조회
  2. 유효기간 확인 (expiresAt > now)
  3. projects/{projectId}/members/{userId} 생성 (role, displayName, avatarUrl)
  4. projects/{projectId}.memberIds 배열에 userId 추가 (arrayUnion)
  5. projects/{projectId}/invites/{inviteId}.useCount 증가
  6. 성공 시 projectId 반환
에러:
  - 토큰 없음: 'not-found'
  - 만료됨: 'deadline-exceeded'
  - 이미 멤버: 'already-exists'
```

### 7.2 Trash 자동 정리 (Scheduled Function)

```
함수명: cleanupTrash
트리거: Cloud Scheduler (매일 03:00 UTC)
동작:
  1. 모든 users/{uid}/tasks에서 deletedAt이 30일 이상 지난 문서 조회
  2. 모든 projects/{pid}/tasks에서 deletedAt이 30일 이상 지난 문서 조회
  3. batch delete
```

### 7.3 계정 삭제 (Callable Function)

```
함수명: deleteAccount
트리거: Callable
동작:
  1. users/{uid}/tasks 전체 삭제
  2. 사용자가 owner인 프로젝트: 태스크 전체 삭제 + 프로젝트 삭제 + 관련 inviteTokens 삭제
  3. 사용자가 멤버인 프로젝트: members에서 제거 + memberIds에서 제거
  4. users/{uid} 문서 삭제
  5. Firebase Auth에서 사용자 삭제
```

### 7.4 마감 리마인더 (Scheduled Function)

```
함수명: sendReminders
트리거: Cloud Scheduler (매 15분)
동작:
  1. 모든 사용자의 태스크 중 reminderOffset이 설정되고, dueDate + startTime - reminderOffset이 현재 시각 범위 (± 7.5분) 내인 것 조회
  2. reminderSentAt이 null인 것만 (중복 방지)
  3. FCM 토큰으로 푸시 발송
  4. reminderSentAt 업데이트
```

### 7.5 일일 요약 (Scheduled Function)

```
함수명: sendDailySummary
트리거: Cloud Scheduler (매 시간)
동작:
  1. settings.dailySummaryEnabled == true인 사용자 중 dailySummaryTime이 현재 시간인 사용자 조회
  2. 해당 사용자의 오늘 태스크 수 계산
  3. FCM 토큰으로 "오늘 N개의 할 일이 있어요" 푸시 발송
```

### 7.6 협업 알림 (Firestore Trigger)

```
함수명: onProjectTaskWrite
트리거: onDocumentWritten('projects/{projectId}/tasks/{taskId}')
동작:
  1. 변경자(lastEditorId)가 아닌 다른 멤버들에게 FCM 푸시 발송
  2. 알림 내용: "{이름}님이 '{태스크 제목}'을 수정했습니다"
  3. 알림 데이터: projectId, taskId (딥링크용)
```

---

## 8. 누락 화면 보충

### 8.1 온보딩 화면 (첫 로그인 시)

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│     반가워요!                    │
│     이름을 알려주세요.            │
│                                 │
│  ┌─────────────────────────┐    │
│  │  표시 이름 입력...        │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │        시작하기           │    │
│  └─────────────────────────┘    │
│                                 │
│  건너뛰기                        │
│                                 │
└─────────────────────────────────┘
```

동작: 이름 입력 후 "시작하기" → `users/{uid}.displayName` 저장 → 알림 권한 요청 다이얼로그 → Inbox로 이동. "건너뛰기" 시 이름 없이 진행.

### 8.2 이메일 로그인/회원가입 화면

```
┌─────────────────────────────────┐
│  [<]  이메일로 로그인             │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │  이메일                   │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  비밀번호                 │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │        로그인             │    │
│  └─────────────────────────┘    │
│                                 │
│  비밀번호를 잊으셨나요?           │
│                                 │
│  ─────── 또는 ───────           │
│                                 │
│  계정이 없으신가요? 회원가입      │
│                                 │
└─────────────────────────────────┘
```

회원가입 화면: 이메일 + 비밀번호(8자 이상) + 비밀번호 확인 + "가입하기" 버튼. 가입 후 이메일 인증 링크 발송 → "이메일을 확인해주세요" 안내 화면.

비밀번호 재설정: 이메일 입력 → "재설정 링크 보내기" → `FirebaseAuth.sendPasswordResetEmail()` 호출.

### 8.3 초대 수락 화면

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│  📋 프로젝트 초대                │
│                                 │
│  홍길동님이 "프로젝트 A"에       │
│  초대했습니다.                    │
│                                 │
│  역할: Editor (수정 가능)        │
│                                 │
│  ┌─────────────────────────┐    │
│  │      초대 수락하기         │    │
│  └─────────────────────────┘    │
│                                 │
│  거절하기                        │
│                                 │
└─────────────────────────────────┘
```

비로그인 상태: 로그인 화면으로 리다이렉트 → 로그인 후 초대 수락 화면으로 복귀 (딥링크 파라미터 유지).

### 8.4 반복 설정 Bottom Sheet

```
┌─────────────────────────────────┐
│  ─── (드래그 핸들)              │
│                                 │
│  반복 설정                       │
│                                 │
│  ○ 안 함                        │
│  ● 매일                         │
│  ○ 평일 (월-금)                 │
│  ○ 주말 (토-일)                 │
│  ○ 매주                         │
│  ○ 매월                         │
│  ○ 매년                         │
│  ○ 커스텀...                    │
│                                 │
│  [커스텀 선택 시]                │
│  매 [2] [주] 마다                │
│  [월] [화] [수] [목] [금] [토] [일] │
│                                 │
└─────────────────────────────────┘
```

### 8.5 프로젝트 색상 선택 피커

```
┌─────────────────────────────────┐
│  프로젝트 색상                    │
│                                 │
│  🔵 🟢 🟠 🔴                   │
│  🟣 🩵 🩷 🔷                   │
│                                 │
│  [선택 시 즉시 적용, 시트 닫힘]   │
└─────────────────────────────────┘
```

### 8.6 날짜 피커

M3 DatePicker 위젯 사용 (Flutter `showDatePicker`). 추가 단축키 칩:

```
[오늘] [내일] [다음 주 월] [없음]
```

칩 탭 시 해당 날짜 즉시 선택. "없음" 탭 시 마감일 제거.

### 8.7 프로젝트 선택 피커

```
┌─────────────────────────────────┐
│  ─── (드래그 핸들)              │
│                                 │
│  프로젝트 선택                    │
│                                 │
│  📥 Inbox           ✓          │
│  🔵 프로젝트 A                  │
│  🟢 프로젝트 B                  │
│  🟠 프로젝트 C                  │
│                                 │
└─────────────────────────────────┘
```

---

## 9. 기술 상세 명세

### 9.1 홈 위젯 상세

패키지: `home_widget` (Flutter)

```
위젯 업데이트 시점:
- 태스크 완료/추가/삭제 시
- 앱 백그라운드 진입 시
- 푸시 알림 수신 시

위젯 → 앱 통신:
- 체크박스 탭 → AppWidgetProvider에서 taskId 전달
- 앱에서 해당 태스크 완료 처리 + 위젯 갱신

위젯 데이터:
- SharedPreferences에 Today 태스크 JSON 저장
- home_widget.saveWidgetData()로 네이티브에 전달

4x2 위젯: 최대 3개 태스크 표시 + "N개 더 보기"
4x4 위젯: 최대 7개 태스크 표시 + "N개 더 보기"
```

**Android 네이티브 위젯 스펙:**
- 레이아웃: XML (RemoteViews 제약)
- 배경: Surface 색상 (Light/Dark 대응), radius-md (12dp) 라운드
- 타이틀: "Today" + 날짜, Title Medium, On Surface
- 태스크 행: 체크박스(20dp) + 제목(Body Medium), 행 높이 40dp
- 체크박스 색상: Primary(미완료 outline), Primary(완료 fill)
- "N개 더 보기" 텍스트: Body Small, On Surface Variant
- 전체 패딩: 16dp

### 9.2 FCM 푸시 알림 상세

```
알림 채널 (Android):
- todostory_reminders: 마감 리마인더 (high importance)
- todostory_daily: 일일 요약 (default importance)
- todostory_collab: 협업 알림 (default importance)

클라이언트 처리:
1. 앱 시작 시 FCM 토큰 발급 → users/{uid}.fcmToken에 저장
2. 토큰 갱신 시 자동 업데이트
3. 포그라운드: flutter_local_notifications로 표시
4. 백그라운드: 시스템 notification
5. 탭: 딥링크로 해당 태스크 상세 열기

알림 payload:
{
  "notification": {
    "title": "마감 30분 전",
    "body": "보고서 마감"
  },
  "data": {
    "type": "reminder|daily|collab",
    "taskId": "...",
    "projectId": "..." // 프로젝트 태스크인 경우
  }
}
```

### 9.3 반복 태스크 생성 로직

```dart
DateTime calculateNextDueDate(Task completedTask) {
  final base = completedTask.dueDate != null
    ? DateTime.parse(completedTask.dueDate!)
    : DateTime.now();

  switch (completedTask.repeat) {
    case 'daily': return base.add(Duration(days: 1));
    case 'weekdays': return nextWeekday(base);
    case 'weekends': return nextWeekend(base);
    case 'weekly': return base.add(Duration(days: 7));
    case 'monthly': return DateTime(base.year, base.month + 1, base.day);
    case 'yearly': return DateTime(base.year + 1, base.month, base.day);
    case 'custom':
      final config = completedTask.repeatConfig!;
      switch (config.unit) {
        case 'day': return base.add(Duration(days: config.frequency));
        case 'week': return nextMatchingWeekday(base, config);
        case 'month': return DateTime(base.year, base.month + config.frequency, base.day);
        case 'year': return DateTime(base.year + config.frequency, base.month, base.day);
      }
  }
}

// 완료 시 호출:
// 1. 기존 태스크 completed = true, completedAt = now
// 2. 새 태스크 생성: 기존 태스크 복제 + 새 id + 새 dueDate + completed = false + completedAt = null
```

### 9.4 프로젝트 삭제 시 동작

- 프로젝트 삭제 → 해당 프로젝트의 모든 태스크가 각 멤버의 개인 Inbox로 복사 (Cloud Functions에서 처리)
- 공유 프로젝트는 Owner만 삭제 가능
- 삭제 전 확인 다이얼로그: "프로젝트를 삭제하면 모든 멤버가 접근할 수 없게 됩니다. 태스크는 각 멤버의 Inbox로 이동합니다."
- Cloud Functions `deleteProject`:
  1. `projects/{pid}/tasks` 전체를 각 멤버의 `users/{uid}/tasks`로 복사
  2. `projects/{pid}/members`, `projects/{pid}/invites` 삭제
  3. 관련 `inviteTokens` 삭제
  4. `projects/{pid}` 삭제

### 9.5 다국어(i18n) 구현

```
패키지: flutter_localizations + intl
파일 위치: lib/core/l10n/

app_ko.arb (한국어 - 기본)
app_en.arb (영어)

생성 명령: flutter gen-l10n

사용법:
  AppLocalizations.of(context)!.inboxEmpty
  → "모든 할 일을 처리했어요!" (ko)
  → "All tasks done!" (en)

번역 키 네이밍 규칙:
  - 화면명_요소_설명: inbox_empty_title, today_empty_subtitle
  - 공통: common_cancel, common_delete, common_undo
  - 에러: error_network, error_permission

설정에서 언어 변경 시:
  1. UserSettings.language 업데이트
  2. App의 locale 변경 → 즉시 반영 (앱 재시작 불필요)
```

---

## 10. 에러 핸들링 전략

### 10.1 에러 분류 및 처리

| 에러 유형 | 감지 방법 | UI 처리 | 복구 전략 |
|----------|----------|---------|----------|
| 네트워크 끊김 | ConnectivityResult 모니터링 | 상단 "오프라인" 배너 | Firestore offline cache로 읽기. 쓰기는 pending queue → 재연결 시 자동 동기화 |
| Firestore 쓰기 실패 | catch FirebaseException | "저장에 실패했습니다" 토스트 | Firestore SDK가 자동 재시도. 영구 실패(permission-denied 등)만 토스트 |
| permission-denied | FirebaseException.code == 'permission-denied' | "권한이 없습니다" 토스트 + Optimistic UI 롤백 | 로컬 캐시가 서버와 동기화되며 자동 롤백 |
| 인증 만료 | authStateChanges() → null | 로그인 화면으로 이동 | Firebase SDK가 자동 refresh 시도 후 실패 시에만 발생 |
| 초대 토큰 무효 | Cloud Function 에러 응답 | "초대 링크가 만료되었습니다" 화면 | 없음 (사용자에게 새 링크 요청 안내) |
| 공유 프로젝트 삭제됨 | Firestore 리스너에서 문서 삭제 감지 | "이 프로젝트는 더 이상 존재하지 않습니다" 다이얼로그 → Inbox로 이동 | 없음 |
| 일반 예외 | try-catch | "문제가 발생했습니다" 토스트 | 로그 기록 (향후 Crashlytics 연동) |

### 10.2 Repository 에러 처리 패턴

```dart
// 모든 Repository 메서드는 다음 패턴을 따름:
class TaskRepository {
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _taskRef(taskId).update(data);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AppException.permissionDenied();
      }
      throw AppException.firestoreError(e.message);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }
}

// UI 레벨에서 처리:
try {
  await ref.read(taskRepositoryProvider).updateTask(taskId, data);
} on AppException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.localizedMessage(context))),
  );
}
```

---

## 11. 개발 로드맵 (5주)

> 1개월(4주) 목표에서 버퍼 1주를 추가한 현실적 일정. 핵심 기능을 앞에 배치하여 4주차에 내부 테스트가 가능하도록 한다.

### Week 1: 프로젝트 기반

- Flutter 프로젝트 셋업 (Firebase 프로젝트 생성, FlutterFire CLI 설정)
- 디자인 시스템 기본 구현 (테마, 컬러, 타이포, 스페이싱)
- 다국어 설정 (ARB 파일, flutter_localizations)
- 인증 (Firebase Auth: Google OAuth + Email 로그인 + 온보딩)
- 사이드 드로어 네비게이션 쉘 (go_router)
- Firestore Security Rules 초기 배포

### Week 2: 태스크 코어

- Firestore 데이터 모델 + Repository 구현
- Riverpod Provider 구조 세팅 (taskStreamProvider + 파생 Provider들)
- 태스크 CRUD (생성, 조회, 수정, 삭제)
- Inbox / Today 뷰
- 인라인 입력 (Fixed Bottom)
- 태스크 상세 Bottom Sheet (제목, 메모, 마감일)
- 체크 완료 + "완료됨" 섹션

### Week 3: 태스크 확장 + 프로젝트

- Upcoming 뷰 (날짜 그룹핑)
- DnD 재정렬 (ReorderableListView + Dismissible 공존)
- 서브태스크, 반복 설정
- 프로젝트 CRUD + 프로젝트별 뷰
- 스와이프 삭제 + Trash 화면
- 다크 모드

### Week 4: 협업 + 모바일 특화

- Cloud Functions 배포 (초대 수락, Trash 정리, 계정 삭제)
- 협업/공유 (초대 링크, 멤버 관리, Realtime 동기화)
- 설정 화면
- 홈 위젯 (Today)
- 푸시 알림 (FCM) + 알림 권한 요청 + Cloud Functions (리마인더, 일일 요약, 협업 알림)
- 딥링크 (Firebase Dynamic Links)
- 완료 애니메이션, 햅틱, 사운드

### Week 5: QA + 배포

- 전체 기능 통합 테스트
- 버그 수정 & 성능 최적화
- 엣지 케이스 처리 (오프라인, 권한, 에러)
- Play Store 배포 준비 (스크린샷, 설명, 등급)
- 내부 베타 배포 → 피드백 반영 → 정식 출시

---

## 12. 성능 목표

| 지표 | 목표 |
|------|------|
| 콜드 스타트 | 2초 이내 |
| 태스크 목록 로딩 | 500ms 이내 (Firestore 캐시 히트 시 즉시) |
| 태스크 생성 반응 | 즉시 (Firestore local write) |
| 애니메이션 프레임 | 60fps |
| APK 크기 | 25MB 이하 |
| 메모리 사용량 | 100MB 이하 |
