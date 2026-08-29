# Current Sprint - Sprint 14.6: Sector Exit Branching & Route Intel

**Status:** COMPLETE (VERIFIED & READY FOR HUMAN UAT)

## Hypothesis
A sector exposing 1–3 physically distinct outbound railway corridors at its eastern boundary, paired with bounded route intelligence (destination type, confidence, prospects, condition, hazards) and physical train steering/departure, makes route selection a core strategic decision while preserving forward-only, disposable procedural generation without global pre-generated maps.

## Scope Contract
- **Physical Multi-Corridor Exits**:
  - Procedural sectors generate 1 to 3 distinct physical outbound corridors at the right/east boundary.
  - Each exit is a physically reachable track segment with its own switch routing and turnout geometry.
  - Exits map to strategic onward railway profiles (`industrial_corridor`, `agricultural`, `settlement`, `declining`, `branch`, `forward`/`main`).
- **Bounded Route Intelligence**:
  - Each outbound exit provides rich route intelligence:
    - `confidence`: (`HIGH`, `MODERATE`, `LOW`)
    - `destination_type`: Human-readable destination archetype
    - `food_prospects`, `parts_prospects`, `fuel_prospects`: Prospect assessments
    - `rolling_stock`: Expected abandoned/derelict rolling stock
    - `rail_condition`: Ballast/track condition summary
    - `known_hazards`: Array of known structural/operational hazards
- **Physical Selection & Just-In-Time Generation**:
  - Player physically drives train onto the chosen corridor.
  - Crossing exit boundary on a specific segment captures the crossed exit definition.
  - Updates `RunState.route_choice` and `RunState.next_sector_profile`.
  - Next sector is deterministically generated biasing the selected route profile.
  - Previous sector is destroyed; train consist, crew, resources, and power state seamlessly carry over.
- **RNG Stream Isolation**:
  - `STREAM_TOPOLOGY` for outbound module decisions.
  - `STREAM_WORLD_ENTITIES` for route intel metadata.
  - `STREAM_SPATIAL` for turnout and corridor geometry.
  - `STREAM_ARCHETYPE` for next-sector biased archetype selection.

## Explicit Exclusions
Do not implement during Sprint 14.6:
- Continental / global world map screens;
- Backward sector travel / revisitation;
- Timetables or signalling interlocks;
- Economy or trade networks;
- Final art, animations, or UI overhauls.

## Acceptance
Sprint 14.6 is complete when:
1. Procedural sectors deterministically generate 1–3 distinct physical outbound corridors across all 6 archetypes.
2. Every outbound corridor is physically reachable via track switches from the entry node.
3. Every outbound corridor exposes complete, schema-valid route intelligence and operational requirements.
4. Player UI clearly renders available routes, alignment status, and route intel blocks.
5. Physically driving the train onto an exit corridor transitions the train to a new sector generated with the chosen route context.
6. Persistent train, consist, crew, and resource states carry over without duplication or loss.
7. 600-sector sweep runs with 100% determinism, 0 validation errors, and 0 generation defects.
8. Full regression suite passes across all sprints (Sprint 10–14.6).
