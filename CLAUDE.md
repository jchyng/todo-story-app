
## Git 커밋 규칙

코드 작업 시 항상 **원자적 단위**로 커밋한다.

- 하나의 커밋 = 하나의 논리적 변경 (기능 추가, 버그 수정, 설정 변경 등)
- 여러 변경이 있을 경우 반드시 나눠서 커밋한다
- 커밋 메시지는 `type: 설명` 형식 (feat / fix / chore / refactor / docs / test)
- 커밋 전 `flutter analyze`가 통과하는 상태여야 한다

---

## Design System
Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.

---

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
