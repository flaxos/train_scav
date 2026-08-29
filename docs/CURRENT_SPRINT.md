# Current Sprint - Sprint 12: Mobility, Burden & Route Requirements

**Status:** PLANNING — SCOPE CONTRACT UNDER REVIEW

## Hypothesis
Train composition becomes strategically meaningful when routes can express simple requirements against existing train properties/capabilities.

The player should experience real operational consequences for train configuration:
- Route exits can define physical thresholds (mass, length) and required capabilities.
- The train's physical mobility summary is evaluated deterministically against route requirements.
- Attempting to cross an exit branch with unmet requirements blocks departure with an explicit, human-readable reason.
- Eligible routes allow normal irreversible departure.

## Scope Contract
- Introduce a standardized `TrainMobilitySummary` contract representing active train mass, length, traction authority, and rolling-stock capabilities.
- Introduce an explicit `RouteRequirements` schema for `SectorDefinition` route exits (max mass, max length, required traction, required capabilities).
- Introduce a deterministic `RouteRequirementEvaluator` to evaluate mobility against route requirements.
- Wire route requirement evaluation into `SectorLifecycle.can_depart()` and departure boundary checks.
- Keep authored Sectors 0-1 intact with data-driven route requirements (e.g. `industrial_exit` requiring `workshop` capability; `settlement_exit` requiring `crew_accommodation`).
- Ensure all default/baseline procedural sector exits remain traversable by standard consists.
- Surface train mobility summary and route requirement feedback in the debug panel and departure modal.

## Explicit Exclusions
Do not implement during Sprint 12:
- multi-locomotive control or traction summation;
- infrastructure hazards or damage simulation (bridge collapse, tight tunnels, broken rail);
- fuel cost rebalancing;
- permadeath or game-over states from failed route requirement checks;
- breaking existing Sprint 1-11 baseline routes;
- a generic scripting or rule engine;
- new procedural archetypes;
- new rolling-stock types;
- changes to sector disposal or save/load mechanics.

## Shared Contracts

### Train Mobility Summary
```gdscript
{
    "total_mass": 215.0,              # float: total mass in tonnes
    "total_length": 260.0,            # float: total consist length in px
    "unit_count": 4,                  # int: number of active rolling-stock units
    "has_traction": true,             # bool: true if operational powered loco is crewed & selected
    "powered_unit_id": "L",           # String: ID of active locomotive/shunter
    "capabilities": [...],            # Array[String]: sorted unique capability tags
}
```

### Route Requirements
```gdscript
{
    "max_mass": 320.0,                # float (optional, 0.0 = unlimited): max mass in tonnes
    "min_mass": 0.0,                  # float (optional, 0.0 = no min)
    "max_length": 350.0,              # float (optional, 0.0 = unlimited): max length in px
    "max_units": 6,                   # int (optional, 0 = unlimited): max wagon count
    "require_traction": true,         # bool (default true): requires valid traction authority
    "required_capabilities": ["workshop"], # Array[String]: tags that MUST be present on train
}
```

### Evaluation Result
```gdscript
{
    "can_take_route": bool,
    "blocked_reasons": Array[String],
    "primary_reason": String,
    "details": Dictionary,
}
```

## Acceptance
Sprint 12 is complete when:
- `RailMovement.get_mobility_summary()` deterministically reports active consist mass, length, unit count, traction authority, and capabilities.
- `RouteRequirementEvaluator` deterministically evaluates mobility summaries against route requirement dictionaries.
- Crossing an exit branch whose requirements are unmet hard-brakes the train and displays the explicit rejection reason in the status panel.
- Correcting the consist immediately makes the route eligible and allows departure.
- Authored Sector 0 start consist `[L, A, B]` clears Sector 0 departure unconditionally.
- Authored Sector 1 `direct_exit`, `industrial_exit`, and `settlement_exit` express explicit requirements matched to their narrative roles.
- All 6 procedural archetypes across seeds generate valid forward exits that standard consists can depart from.
- Automated unit tests and scripted UAT rehearsals pass cleanly.
