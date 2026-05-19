# Roadmap — implementační balíčky

Tato složka obsahuje **plné specifikace** pro nejbližší produktové fáze. Tracking úkolů: **GitHub Issues** v repozitáři `dictator` (žádný externí nástroj).

| Dokument | Obsah |
|----------|--------|
| [P0-spec.md](./P0-spec.md) | 5 položek — důvěra, vkládání, distribuce |
| [P1-spec.md](./P1-spec.md) | 13 položek — power user, jazyky, modely |
| [../research/voice-dictation-market-research.md](../research/voice-dictation-market-research.md) | Tržní research a backlog R1–R8 |

**Hlavní index roadmapy:** [ROADMAP.md](../../ROADMAP.md)

## GitHub Issues (P0 + P1)

| ID | Issue |
|----|-------|
| P0.1 | [#2](https://github.com/Zdenctorm/dictator/issues/2) |
| P0.2 | [#3](https://github.com/Zdenctorm/dictator/issues/3) |
| P0.3 | [#4](https://github.com/Zdenctorm/dictator/issues/4) |
| P0.4 | [#5](https://github.com/Zdenctorm/dictator/issues/5) |
| P0.5 | [#6](https://github.com/Zdenctorm/dictator/issues/6) |
| P1.1 | [#7](https://github.com/Zdenctorm/dictator/issues/7) |
| P1.2 | [#8](https://github.com/Zdenctorm/dictator/issues/8) |
| P1.3 | [#9](https://github.com/Zdenctorm/dictator/issues/9) |
| P1.4 | [#10](https://github.com/Zdenctorm/dictator/issues/10) |
| P1.5 | [#11](https://github.com/Zdenctorm/dictator/issues/11) |
| P1.6 | [#12](https://github.com/Zdenctorm/dictator/issues/12) |
| P1.7 | [#13](https://github.com/Zdenctorm/dictator/issues/13) |
| P1.8 | [#14](https://github.com/Zdenctorm/dictator/issues/14) |
| P1.9 | [#15](https://github.com/Zdenctorm/dictator/issues/15) |
| P1.10 | [#16](https://github.com/Zdenctorm/dictator/issues/16) |
| P1.11 | [#17](https://github.com/Zdenctorm/dictator/issues/17) |
| P1.12 | [#18](https://github.com/Zdenctorm/dictator/issues/18) |
| P1.13 | [#19](https://github.com/Zdenctorm/dictator/issues/19) |

Po merge roadmap PR vytvoř v GitHubu milestones `v1.1-p0` a `v1.2-p1` a issues přiřaď.

## Jak zakládat issues

1. Každá položka `P0.x` / `P1.x` má v spec souboru sekci **GitHub issue** (title + body).
2. Label návrh: `P0` / `P1`, `area:paste`, `area:transcription`, `area:release`, …
3. Milestone návrh: `v1.1-p0` (všechny P0), `v1.2-p1` (P1 po dokončení P0).

## Definition of Done (společné)

- [ ] Acceptance criteria ze spec splněna
- [ ] Manuální test na macOS 14+ Apple Silicon (uvedené scénáře)
- [ ] Unit testy tam, kde spec požaduje (pure logika)
- [ ] `DiagnosticsLogger` záznamy pro nové failure větve
- [ ] Aktualizace [ROADMAP.md](../../ROADMAP.md) checkboxu položky
