# Current Sprint - Sprint 13: Locomotive Acquisition & Multi-Loco Operations

**Status:** IN PROGRESS

## Hypothesis
Physically recovering another powered locomotive expands the train's available traction and route capability while preserving the single physical-consist model, explicit control authority, and sector persistence.

## Scope Contract
- **Aggregate Traction Model**:
  - Available traction = sum of operational coupled powered units in `active_units`.
  - Baseline: 1 operational locomotive/shunter = 1.0 traction; 2 operational locomotives/shunters = 2.0 traction.
  - Detached, non-operational (damaged), or uncrewed primary units do not contribute traction.
- **One Player Train / Explicit Authority**:
  - There is strictly ONE player train and one explicit controlled unit (`controlled_power_unit_id`).
  - Control authority is never inferred from array index or consist ordering.
  - Wagons are never promoted to control authority.
  - Push/pull multi-loco configurations (e.g. `[L][A][B][S]`, `[S][A][B][L]`, `[A][L][B][S]`) contribute aggregate traction regardless of position.
- **Route Requirements Integration**:
  - Support `min_traction` threshold (e.g. `min_traction: 2.0`) in `RouteRequirementEvaluator`.
  - A route requiring multiple traction units is `[BLOCKED ✕]` when train has 1 loco, and becomes `[AVAILABLE ✓]` when a second loco is physically coupled.
- **Operational UI Presentation**:
  - `OperationalUIPresenter` formats traction capacity, reasons, and physical action hints (`Recover and couple a second operational locomotive/shunter`).
- **Physical Acquisition & Persistence**:
  - Discovery and recovery remains physical: route to it, repair if damaged, shunt and couple.
  - Multiple powered units persist IDs, conditions, types, and consist positions across sector transitions.

## Explicit Exclusions
Do not implement during Sprint 13:
- Independent player trains, fleet AI, or multi-train signalling/dispatch;
- Realistic MU protocols, wheel-slip, adhesion curves, or dynamic braking;
- Fuel economy rebalance or fuel consumption per locomotive;
- New procedural archetypes or terrain hazards;
- Art assets, animations, or UI overhauls.

## Acceptance
Sprint 13 is complete when:
- Two powered units can exist in one physical consist.
- Powered-unit identity is persistent and independent of consist order.
- One explicit controlled unit remains authoritative.
- Operational coupled powered units contribute to aggregate traction.
- Detached/non-operational powered units do not contribute.
- Second locomotive is acquired physically.
- Recovering it can change an existing route from blocked to available.
- Multiple powered units survive sector transition.
- Existing coupling/shunting/control behaviour remains correct.
- Full automated regression test suite passes.

