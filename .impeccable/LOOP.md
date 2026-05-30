# Impeccable loop — Locute (Swift / AppKit)

Dlouhodobý backlog pro autonomní iterace `/impeccable` se subagenty. Po každém PR aktualizuj stav a vyber 2–4 položky do dalšího kola.

**North Star:** The Quiet Study · **Register:** product

---

## Iterace 2026-05-30 (`cursor/impeccable-loop-5e15`)

### Hotovo

| ID | Oblast | Změna |
|----|--------|-------|
| L1 | Menu bar | „Vložit znovu“, „Zkopírovat poslední přepis“, náhled v položce, ● Připraveno |
| L2 | Menu bar | `lastTranscriptProvider` z `AppDelegate` |
| L3 | Setup | Diagnostika za disclosure „Potřebuješ pomoc?“ |
| L4 | Setup | Hotkey Law live refresh; VO pro Monitorování vstupu |
| L5 | Předvolby | LLM karta mimo hlavní scroll → disclosure Pokročilé |
| L6 | Copy | Bez „LLM“/model jmen v primární UI; tykání v Launch |
| L7 | Launch | a11y stav + progress; 3 oprávnění v chybové hlášce |
| L8 | Popover | „Vložit znovu“ + VoiceOver labely |

### Další kolo (priorita)

| Pri | Oblast | Úkol | Příkaz |
|-----|--------|------|--------|
| P1 | Launch | Neslučovat hero + historii — okno historie na vyžádání; méně auto-show | `/impeccable distill LaunchWindowController` |
| P1 | Předvolby | Sidebar nebo sekce „Diktování“ / „Přepis“ místo 5 flat karet | `/impeccable layout PreferencesPanelBuilder` |
| P2 | Menu | AppTheme custom menu view (DESIGN gap NSMenu) | craft |
| P2 | HUD | Accent-filled jedno primární CTA v oknech | DESIGN open question |
| P2 | Tests | Aktualizovat testy pokud assertují staré labely modelů | — |
| P3 | Core | `TranscriptionHistoryStore` místo duplicity v AppDelegate | refactor |

### Backlog (critique snapshot)

- Score menu+Hud: 32/40 (`2026-05-30T12-00-00Z__locute-ui-statusbarcontroller-swift.md`)
- Score celé UI: 30/40 (`2026-05-30T12-16-09Z__locute-ui.md`)
- P0 critique „setup+prefs v jednom scrollu“ — částečně vyřešeno (Setup vs Preferences split existuje; LLM z hlavních prefs pryč)

---

## Jak spustit další loop

1. `node .cursor/skills/impeccable/scripts/context.mjs`
2. Paralelní `explore` subagenti: `StatusBarController`, `SetupWindowController`, `Preferences*`, `RecordingOverlayController`
3. Branch `cursor/impeccable-loop-5e15` (nebo nový s `-5e15` suffixem)
4. Implementace P1 z tabulky výše
5. `/impeccable critique Locute/UI` → commit → PR
