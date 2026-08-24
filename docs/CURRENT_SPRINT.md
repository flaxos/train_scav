# Current Sprint — Sprint 9A: Railway Grammar Research & Schema

**Status:** IMPLEMENTED — AUTOMATED VALIDATION READY

## Hypothesis
A research-derived semantic railway/world grammar can describe procedural sector meaning before geometry, while preserving the physical train, crew, scavenging and sector lifecycle systems validated through Sprint 8.

Sprint 9A proves the description layer only:

RESEARCH REPORTS -> SOURCE-NEUTRAL ONTOLOGY -> VERSIONED JSON SCHEMA -> CANONICAL FIXTURES -> VALIDATOR -> TEST SEED CONTRACT

Roadmap acceptance:
> The project has an explicit, versioned semantic railway/world schema and validated reference fixtures that later Sprint 9 generation work can consume without hard-coding authored yards or depending directly on external map tags.

## Baseline Dependencies
Sprint 9A builds on the completed Sprint 1-8 systems and docs:
- rail-space movement, points, coupling, uncoupling and contact;
- crew tasks as orchestration over rail authority;
- sector lifecycle with irreversible forward disposal;
- POI/search/haul/deposit ownership semantics;
- Sprint 8 vertical-slice scenario composition;
- `docs/deep-research-report-grammer.md` and `docs/deep-research-report-prompts.md` as raw research inputs.

Do not replace `RailMovement`, `SectorInstance`, `SectorPOIs`, coupling, sector lifecycle or the vertical-slice scenario in 9A.

## In Scope
The active build should add the smallest durable foundation for later procedural railway sectors:
1. Curated worldgen docs under `docs/worldgen/` summarising the research-backed grammar and governance rules.
2. A source-neutral semantic rail graph model with nodes, track edges and internal roles such as `THROUGH_MAIN`, `PASSING_LOOP`, `GOODS_YARD_TRACK`, `LOADING_TRACK`, `HEADSHUNT` and `AGRICULTURAL_SPUR`.
3. A separate world relationship graph for station, road, creek, bridge, industry, goods shed, POI and settlement meaning.
4. Canonical runtime JSON fixtures under `data/worldgen/`.
5. A human-readable YAML archetype copy for authoring/reference only.
6. A deterministic test-seed contract for later 9B-9D increments.
7. A focused validator and tests proving valid fixtures pass and malformed fixtures fail predictably.

## Authority Rules
- **Research docs own** provenance, terminology mapping and corpus method.
- **Worldgen schema owns** initial semantic description of generated sector meaning.
- **Runtime rail owns** physical movement, topology, rolling stock, consist order, contact, coupling, uncoupling and powered control.
- **Sector lifecycle owns** irreversible departure and disposable sector runtime state.
- **Generated blueprints later may author initial state** but must not become live gameplay authority after sector instantiation.

Critical invariants:
- internal runtime fixtures must use source-neutral roles, not raw OSM/ORM tags such as `service=siding`;
- station, road, creek, bridge, goods shed and industry are world entities/relations, not railway-routing vertices;
- JSON is canonical at runtime; YAML is reference/authoring only;
- no real station geometry is copied into shipped fixtures;
- design priors, observed facts, inferred relationships and gameplay abstractions must remain distinguishable.

## Explicit Exclusions
Do NOT implement in Sprint 9A:
- procedural sector generation;
- semantic graph randomisation;
- rail geometry embedding;
- generated POI or rolling-stock placement;
- shunting solvability search;
- runtime `RailMovement` data loading;
- changes to coupling, point physics, crew tasks or sector lifecycle;
- YAML parsing dependency at runtime;
- OSM/ORM data import pipeline;
- signalling/interlocking, timetable simulation, combat, factions, trading, weather, save/load or final art.

## Automated Acceptance
- [x] Research reports are present as raw inputs.
- [x] Curated worldgen docs identify the semantic-first approach and provenance rules.
- [x] Runtime JSON schema/archetype files are versioned.
- [x] Human-readable YAML reference archetype exists but is not required by runtime validation.
- [x] Canonical fixtures use source-neutral railway roles instead of raw external map tags.
- [x] Validator accepts the valid central European small-town station fixture.
- [x] Validator rejects a missing-entry fixture with an entry-specific error.
- [x] Validator rejects a bad-reference fixture naming the unknown node.
- [x] Test-seed contract records fixed future acceptance seeds.
- [x] Existing Sprint 1-8 regression tests remain green.
- [x] Headless launch has no parse/compile/runtime script errors.

## Human Review Gate
Sprint 9A has no playable procedural-sector UAT. It is complete when the user accepts that the schema, fixtures, docs and validator are the right foundation for Sprint 9B.

## Definition of Done
Sprint 9A is complete only after the 9A automated test passes, the existing regression suite remains green, and the user accepts the schema/docs direction.

## Next Possible Increment
Sprint 9B — Deterministic Semantic Railway Generation.

Do not begin 9B until 9A is accepted. 9B may generate semantic graphs from seeds but still must not embed physical rail geometry or replace live railway authority.
