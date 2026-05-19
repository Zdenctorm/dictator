# Dictator — produktová roadmapa

> **Účel:** Jednotný přehled toho, co Dictator umí dnes, co plánujeme jako další krok, a jaké možnosti produkt může nabídnout dlouhodobě.  
> **Poslední revize:** květen 2026  
> **Související:** [OVERVIEW.md](./OVERVIEW.md) (technický přehled), [PLAN.md](./PLAN.md) (implementační spec MVP), [RELEASING.md](./RELEASING.md) (vydávání verzí)

---

## Vize

**Dictator** je soukromé české diktování pro macOS: drž klávesu, mluv, pusť — text se objeví tam, kde máš kurzor. Bez cloudu, bez účtu, bez telemetrie.

Cílový uživatel: knowledge worker na Macu (právníci, analytici, vývojáři, ops, product) — kdokoli, kdo píše hodně textu a nechce posílat hlas ani přepisy na cizí servery.

---

## Produktové principy (nemění se)

| Princip | Co to znamená v praxi |
|--------|------------------------|
| **Offline-first** | Přepis běží lokálně (WhisperKit). Síť jen při stažení modelu a kontrole aktualizací. |
| **Soukromí** | Žádná analytika, žádný crash reporter, žádné API pro přepis. Audio jen v RAM / dočasný WAV, po přepisu smazat. |
| **Push-to-talk** | Aktivace vědomým gestem — ne poslouchá na pozadí nepřetržitě. |
| **Funguje všude** | Text jde do aktivní aplikace (Mail, Slack, Terminál, prohlížeč, …), ne do vlastního editoru. |
| **Čeština first** | Jazyk `cs` je výchozí; další jazyky až jako explicitní volba. |

---

## Stav dnes — co produkt už umí

Tyto položky jsou **implementované** v aktuální codebase (viz [OVERVIEW.md](./OVERVIEW.md)).

### Jádro diktování

- [x] Push-to-talk globální klávesou (CGEventTap, `flagsChanged`)
- [x] Diktování z menu bez klávesy („Začít diktování“)
- [x] Lokální přepis WhisperKit **large-v3**, jazyk **čeština**
- [x] Vložení textu do cílové aplikace (Accessibility API nebo Cmd+V podle typu appky)
- [x] Zachycení cílové aplikace **na začátku** nahrávání (focus drift po puštění klávesy)
- [x] Per-app strategie vkládání ([`PasteInsertionPlan`](./Dictator/Core/PasteInsertionPlan.swift) — terminály, Electron, prohlížeče)
- [x] Minimální délka nahrávky (~0,3 s) — krátký stisk nic neudělá
- [x] Detekce příliš tichého audia — uživatelská zpětná vazba místo prázdného přepisu

### Kvalita přepisu

- [x] Filtrace známých Whisper halucinací (titulky, „thanks for watching“, …)
- [x] Vlastní / naučený slovník s prompt-bias v decoderu + post-process náhrady variant
- [x] Výchozí seed slovníku (KYC, AML, SEPA, blockchain, …)
- [x] **LearningEngine** — pasivné učení z retry (< 8 s), ruční opravy v historii, potvrzení termínů
- [x] UI „Co se Dictator naučil“ + migrace ze starého formátu slovníku
- [x] Označení nízké/střední jistoty slov v historii (vizuální podtržení)

### UX a rozhraní

- [x] Menu bar aplikace (žádná ikona v Docku při běžném režimu)
- [x] HUD overlay během nahrávání / přepisu / vložení
- [x] Hlavní okno: stav startu, stahování modelu, **historie přepisů** (kopírovat / vložit znovu)
- [x] Oprávnění: mikrofon + Accessibility, průvodce nastavením
- [x] Volba diktovací klávesy: levý/pravý Option, oba, pravý Command (AltGr kolize)
- [x] Spuštění po přihlášení (SMAppService)
- [x] Light + dark mode, brand (claret + cream)
- [x] Přístupnost: role, popisy, VoiceOver-friendly menu

### Provoz a distribuce

- [x] Sparkle auto-update (appcast, EdDSA)
- [x] Release skripty (build, DMG, podpis, notarizace — viz [RELEASING.md](./RELEASING.md))
- [x] Lokální diagnostické logy (`~/Library/Logs/Dictator/`)
- [x] Režim „Ověřit přepis“ (zobrazí text bez vložení)

### Známá omezení (ne bugy, ale hranice produktu)

- První spuštění stáhne ~3 GB modelu (internet jednorázově)
- Pouze **Apple Silicon** (M1+)
- **Sandbox vypnutý** — nelze Mac App Store v současné podobě
- Gatekeeper varování u nepodepsaných buildů (notarizace v pipeline, certifikát na roadmapě)
- Občasné chyby velikosti písmen u krátkých technických slov (řeší se post-procesem)

---

## Jak číst roadmapu

| Priorita | Význam | Orientační horizont |
|----------|--------|---------------------|
| **P0** | Důležité pro důvěru a každodenní použití; mělo by přijít brzy | nejbližší release |
| **P1** | Výrazně lepší produkt pro power usery | 1–2 větší iterace |
| **P2** | Firemní / týmové scénáře | až po stabilním jádru |
| **P3** | Experimenty, širší platforma, „nice to have“ | bez závazku |

Stav: `[x]` hotovo · `[ ]` plánováno · `[~]` částečně / v přípravě

---

## P0 — Kvalita každodenního diktování

Cíl: uživatel diktuje bez obav o schránku, formátování a selhání vložení.

| # | Funkce | Popis | Stav |
|---|--------|--------|------|
| P0.1 | **Obnova schránky** | Před Cmd+V uložit clipboard; po vložení obnovit, pokud ho mezitím nic nepřepsalo | [ ] |
| P0.2 | **Smart leading space** | Při vložení doprostřed věty doplnit mezeru jen když je potřeba (kontext kolem kurzoru) | [ ] |
| P0.3 | **Normalizace velikosti písmen** | ALL-CAPS slova → lowercase kromě whitelistu (KYC, AML, API, …) | [ ] |
| P0.4 | **HUD při chybě vložení** | Když AX i Cmd+V selžou, jasná zpráva + odkaz na historii / zkopírovat | [ ] |
| P0.5 | **Apple Developer ID + notarizace** | Distribuce bez „Apple cannot check“ — skripty existují, chybí produkční cert | [~] |

---

## P1 — Lepší přepis a ovládání

Cíl: Dictator se cítí jako „profesionální nástroj“, ne jen MVP.

### Příkazy a formátování hlasem

| # | Funkce | Popis |
|---|--------|--------|
| P1.1 | **Interpunkční příkazy** | „tečka“, „čárka“, „otázník“, „nový odstavec“, „nový řádek“ → symboly / `\n` |
| P1.2 | **Čísla a data** | „dvacet tři“, „1. 5. 2026“ → konzistentní normalizace podle kontextu |
| P1.3 | **Undo posledního vložení** | Jedním gestem / menu vrátit poslední vložený blok (kde to OS dovolí) |
| P1.4 | **Režim „zkontroluj před vložením“** | Volitelně: přepis jen do panelu, uživatel potvrdí Enter / tlačítkem |

### Model a výkon

| # | Funkce | Popis |
|---|--------|--------|
| P1.5 | **Volba modelu** | large-v3 (přesnost) vs. menší model (rychlost / méně RAM) — uživatelské nastavení |
| P1.6 | **Průběžný přepis (streaming)** | Částečný text během dlouhého drženého Option (náročné na UX i WhisperKit) |
| P1.7 | **Přednačtení modelu na pozadí** | Rychlejší první diktát po startu Macu (launch agent + idle warm-up) |

### Personalizace

| # | Funkce | Popis |
|---|--------|--------|
| P1.8 | **Export / import slovníku** | JSON nebo plain text pro zálohu a sdílení mezi stroji |
| P1.9 | **Profil slovníku podle aplikace** | Jiný bias ve Slacku vs. v Terminálu (bundle ID → slovník) |
| P1.10 | **Ruční úprava slovníku v UI** | Editor všech termínů (ne jen „naučených“) na jednom místě |

### Jazyky

| # | Funkce | Popis |
|---|--------|--------|
| P1.11 | **Angličtina** | Volba jazyka v nastavení, stejný offline flow |
| P1.12 | **Slovenština** | Stejné jako EN — blízký jazyk, vysoká poptávka v regionu |
| P1.13 | **Automatická detekce jazyka** | Jedna nahrávka — Whisper `language=auto` + UI indikace |

---

## P2 — Tým, firma, compliance

Cíl: nasaditelnost v organizaci bez kompromisu na soukromí.

| # | Funkce | Popis |
|---|--------|--------|
| P2.1 | **Sdílený týmový slovník** | Import firemního glossary (domény, produkty, zákazníci) — bez cloudu, soubor / MDM |
| P2.2 | **MDM / silent install** | PKG, konfigurace oprávnění, dokumentace pro IT |
| P2.3 | **Zásady uchovávání** | Vypnout historii přepisů na disku; volitelná doba retence; export jen lokálně |
| P2.4 | **Audit log (lokální)** | Kdo kdy diktoval — jen metadata (čas, délka, app bundle), **ne** obsah textu |
| P2.5 | **Privacy report** | Jednostránkový přehled „co Dictator neodesílá“ pro security review |
| P2.6 | **Správa modelu offline** | Stažení modelu z interního mirroru (air-gapped sítě) |

---

## P3 — Širší produkt a platforma

Cíl: rozšíření dosahu; většina položek závisí na obchodní prioritě, ne na technické nutnosti.

| # | Funkce | Popis | Poznámka |
|---|--------|--------|----------|
| P3.1 | **Kontinuální diktování** | Režim „poslouchám dokud neřeknu stop“ — jiný UX i spotřeba baterie | Konflikt s PTT principem |
| P3.2 | **Druhá klávesová zkratka** | Např. „diktuj do schránky“ vs. „diktuj na kurzor“ | |
| P3.3 | **Integrace se Shortcuts** | Automatizace: „nadiktuj do souboru“, „přidej do poznámky“ | |
| P3.4 | **Menu bar mini-editor** | Rychlá oprava posledního přepisu bez otevření hlavního okna | |
| P3.5 | **Statistiky jen pro uživatele** | Počet slov / čas ušetřený — **100 % lokálně**, opt-in | |
| P3.6 | **Vlastní vzhled HUD** | Velikost, pozice, barva, ztlumení | |
| P3.7 | **Podpora Intel Mac** | Menší model nebo degraded mode | Nízká priorita (ANE) |
| P3.8 | **iOS / iPadOS** | Sdílený engine, jiný vstup (žádný globální event tap) | Samostatný produkt |
| P3.9 | **Windows / Linux** | Jiný stack (není WhisperKit) | Mimo současný stack |
| P3.10 | **Mac App Store edice** | Omezená funkce (bez globálního tapu) nebo jiná architektura | Pravděpodobně ne |

---

## Backlog nápadů (bez priority)

Seznam k diskusi — ne každá položka musí být součástí Dictatoru.

- Hlasové **formátování** („tučně“, „kurzíva“) tam, kde to cílová app podporuje
- **Šablony** — „email začátek“, „ticket popis“ jako makra po diktátu
- **Dvojitý tap Option** — přepnutí mezi režimy (PTT vs. hands-free)
- **Whisper prompt z kontextu** — poslední odstavec z aktivního pole jako hint (souhlas uživatele)
- **Lepší diarizace** — více mluvčích (spíš meeting nástroj)
- **Přepis ze schránky / souboru** — WAV/MP3 drag & drop do okna
- **Synchronizace nastavení přes iCloud** — bez synchronizace obsahu přepisů
- **Plugin API** — post-process řetězec (např. vlastní normalizace firemních ID)
- **Režim „jen čísla“** — formuláře, tabulky
- **Citlivý režim** — po diktátu vymazat historii řádku okamžitě
- **Lokalizace UI** — anglické menu pro mezinárodní týmy

---

## Co Dictator záměrně nedělá

Tyto věci **nejsou** na roadmapě, pokud se nezmění produktová strategie:

| Anti-cíl | Proč |
|----------|------|
| Cloudový přepis (OpenAI, Azure, …) | Porušuje hlavní slib soukromí |
| Ukládání audio na disk dlouhodobě | Riziko úniku citlivých dat |
| Telemetrie / A/B testy | Žádné sledování chování |
| Účty a přihlášení | Zbytečná třecí plocha pro offline nástroj |
| Nepřetržité poslouchání na pozadí | Špatný UX i právní dojem u firem |
| Přepis videohovorů bez souhlasu účastníků | Etické a právní riziko |

---

## Metriky úspěchu (interní)

Bez telemetrie sledujeme úspěch jinak:

- **Adopce:** počet aktivních instalací (odhad z release / feedback)
- **Retence:** uživatel diktuje po 7 a 30 dnech (kvalitativní feedback, support)
- **Kvalita:** podíl retry do 8 s, počet ručních oprav v historii, hlášení „text se nevložil“
- **Distribuce:** podíl uživatelů na notarizovaném buildu bez Gatekeeper friction
- **Výkon:** medián času release klávesy → text v poli (cíl < 3 s u krátkých vět)

---

## Mapování na dokumentaci

| Dokument | Obsah |
|----------|--------|
| [CLAUDE.md](./CLAUDE.md) | MVP cíle a stack (stručně) |
| [PLAN.md](./PLAN.md) | Technický implementační plán pro vývojáře |
| [OVERVIEW.md](./OVERVIEW.md) | Architektura, bezpečnost, co je hotové |
| **ROADMAP.md** (tento soubor) | Produktové směřování a backlog |
| [RELEASING.md](./RELEASING.md) | Jak vydat verzi |

---

## Historie změn roadmapy

| Datum | Změna |
|-------|--------|
| 2026-05 | První verze: konsolidace nápadů z OVERVIEW + rozšíření podle codebase |
