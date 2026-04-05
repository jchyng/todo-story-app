# Design System — TodoStory

## Product Context
- **What this is:** 개인 생산성 Flutter Android 할 일 관리 앱
- **Who it's for:** Google Tasks에서 이탈한 개인 사용자 (한국어)
- **Space/industry:** Personal productivity / todo apps
- **Project type:** Mobile Android app
- **Benchmarked:** MS Todo (UX 구조 기준)

## Aesthetic Direction
- **Direction:** Brutally Minimal
- **Decoration level:** Minimal — 타입과 컬러가 모든 개성을 담당. 장식 없음.
- **Mood:** 개인적이고 따뜻하되, 군더더기 없이 깔끔하다. 기업용 앱이 아닌 내 노트처럼 느껴진다.
- **MS Todo 채택 패턴:** 프로젝트별 컬러 헤더, 접을 수 있는 완료 섹션, 할일 상세 바텀시트, 빠른 추가 바

## Typography

- **UI/Body:** Plus Jakarta Sans
  - Inter보다 따뜻함. 한국어 혼용 환경에서도 잘 작동.
  - 앱 전반의 기본 서체.
- **Timeline 월/연도 헤더:** Fraunces (세리프, Display weight)
  - Timeline 뷰의 월 헤더에만 사용. 완료 기록이 '할일 목록'이 아닌 '일지'처럼 느껴지게.
  - 앱에서 유일하게 세리프체를 쓰는 지점 — 의도적 차별화.
- **숫자/통계:** Geist Mono (tabular-nums)
  - 반복 완료율, 날짜 수치 등에 사용.
- **로딩 전략:** Google Fonts (Plus Jakarta Sans, Fraunces, Geist Mono)

### 타입 스케일
| 레벨 | 크기 | 굵기 | 용도 |
|------|------|------|------|
| Display | 28sp | Bold | 프로젝트 헤더 타이틀 |
| Title | 20sp | SemiBold | 화면 타이틀, Today 날짜 |
| Headline | 17sp | Medium | 할일 제목 |
| Body | 14sp | Regular | 서브텍스트, 메모, 날짜 |
| Label | 12sp | Regular | 배지, 보조 레이블 |
| Mono | 13sp | Regular | 날짜 수치, 통계 (Geist Mono) |

## Color

- **Approach:** Restrained — 1 액센트 + 뉴트럴. 컬러는 드물게, 의미 있게.
- **Background:** `#F8F8F6` — 따뜻한 오프화이트. 순백이 아닌 노트 질감.
- **Surface/Card:** `#FFFFFF`
- **Primary text:** `#1C1C1E`
- **Muted text:** `#6E6E73`
- **Accent:** `#4E7EFF` — MS Todo의 파란색보다 따뜻하고 개인적인 블루.
- **Divider:** `#E5E5EA`

### 프로젝트 테마 컬러 (6종 프리셋)
| 이름 | Hex |
|------|-----|
| 블루 (기본) | `#4E7EFF` |
| 퍼플 | `#9B6DFF` |
| 레드 | `#FF453A` |
| 그린 | `#34C759` |
| 오렌지 | `#FF9F0A` |
| 틸 | `#32ADE6` |

### 시맨틱
- **성공:** `#34C759`
- **경고:** `#FF9500`
- **오류:** `#FF3B30`
- **정보:** `#4E7EFF`

### 다크 모드 전략
- Background: `#1C1C1E`
- Surface: `#2C2C2E`
- Primary text: `#FFFFFF`
- Muted text: `#8E8E93`
- 액센트 채도 10% 낮춤: `#4370E8`

## Spacing
- **Base unit:** 8px
- **Density:** Comfortable
- **화면 여백:** 16px (좌우)
- **할일 항목 간격:** 12px
- **섹션 간격:** 24px

| 토큰 | 값 |
|------|-----|
| 2xs | 2px |
| xs | 4px |
| sm | 8px |
| md | 16px |
| lg | 24px |
| xl | 32px |
| 2xl | 48px |
| 3xl | 64px |

## Layout
- **Approach:** Grid-disciplined — 모바일 리스트 우선.
- **화면 여백:** 16px 고정
- **최대 콘텐츠 폭:** 단일 컬럼 (모바일)
- **Border radius:** sm=4px, md=8px, lg=12px, full=9999px
  - 할일 행: 없음 (전체 폭)
  - 카드/섹션: md(8px)
  - 버튼/칩: full(9999px)
  - 바텀시트: 상단 lg(12px)

### 주요 화면 레이아웃 (MS Todo 기반)
| 화면 | 레이아웃 패턴 |
|------|-------------|
| 홈/사이드바 | 드로어: 아바타+이름, 특수 뷰(오늘/중요/Timeline/Archive), 프로젝트 목록 |
| 프로젝트 상세 | 컬러 헤더 + 할일 리스트 + 완료 섹션(접기) + 하단 빠른 추가 바 |
| 오늘 할 일 | 날짜 대형 헤더 + 시간대별 그라디언트 배경 + 태스크(프로젝트명 서브텍스트) |
| Timeline | Fraunces 월 헤더 + 완료 항목 리스트 (날짜순) + 공유 버튼 |
| Archive | 완료된 프로젝트 목록 + 완료율 배지 |
| 할일 상세 | 바텀시트: 대형 제목 + 서브태스크 + 그룹화된 액션 카드들 |

## Motion
- **Approach:** Intentional — 이해를 돕는 전환만. 화려함 없음.
- **Easing:** enter(ease-out) / exit(ease-in) / move(ease-in-out)
- **Duration:**
  - micro: 50-100ms (아이콘 상태 변화)
  - short: 150-250ms (체크박스 완료 애니메이션)
  - medium: 250-400ms (바텀시트 진입/퇴장, 섹션 접기/펼치기)
  - long: 400-700ms (화면 전환)

### 핵심 인터랙션
- **체크박스 완료:** 원 채우기(accent) + 제목 취소선 (short 200ms)
- **완료 섹션:** 부드러운 접기/펼치기 (medium 300ms)
- **오늘 화면 배경:** 시간대별 그라디언트
  - 아침(06-10): `#FFD89B` → `#19547B`
  - 낮(10-17): `#89F7FE` → `#66A6FF`
  - 저녁(17-21): `#A18CD1` → `#FBC2EB`
  - 밤(21-06): `#0F0C29` → `#302B63`

## Decisions Log
| 날짜 | 결정 | 근거 |
|------|------|------|
| 2026-04-04 | Plus Jakarta Sans (Body) | Inter보다 따뜻함, 한국어 혼용 지원 |
| 2026-04-04 | Fraunces (Timeline 헤더만) | Archive/Timeline 뷰에 '일지' 감성 부여 |
| 2026-04-04 | Background #F8F8F6 | 순백 대신 따뜻한 오프화이트로 개인적 느낌 |
| 2026-04-04 | Accent #4E7EFF | MS Todo 파란보다 따뜻하고 독립적인 블루 |
| 2026-04-04 | 오늘 뷰 그라디언트 배경 | MS Todo 랜덤 사진 대신 시간대별 브랜드 그라디언트 |
| 2026-04-04 | 초기 디자인 시스템 생성 | /design-consultation, MS Todo 벤치마킹 기반 |
