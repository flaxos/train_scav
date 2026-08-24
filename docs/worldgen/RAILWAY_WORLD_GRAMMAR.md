# Railway World Grammar — Central Europe v1

## Purpose
Sprint 9 starts procedural variety by generating meaning before geometry.

The target reference family is:

```text
Central European small-town station
single-track secondary/branch corridor
double-ended passing loop
passenger platform
compact goods yard/loading track
creek crossed by railway bridge
road-served agricultural or light-industrial spur
freight-era decay and salvage opportunity
```

This is an archetype, not a copy of any real station.

## Semantic Rail Graph
The rail graph describes what trains can physically do. It uses routing nodes and track-section edges.

Allowed v1 rail roles:
- `THROUGH_MAIN`
- `PASSING_LOOP`
- `PLATFORM_TRACK`
- `GOODS_YARD_TRACK`
- `LOADING_TRACK`
- `HEADSHUNT`
- `INDUSTRIAL_SPUR`
- `AGRICULTURAL_SPUR`
- `STORAGE_TRACK`
- `DEPOT_TRACK`
- `CROSSOVER`
- `ABANDONED_TRACK`

Use source-neutral roles in runtime fixtures. External source vocabulary such as OSM/OpenRailwayMap `service=siding`, `service=yard` or `service=spur` belongs in research notes or source mapping, not the canonical runtime JSON.

## World Relationship Graph
Station, settlement, road, creek, bridge, goods shed, industry, agricultural facility and future POI concepts belong to a related world graph. They are not railway-routing vertices.

Typical relations:
- `SERVES_SETTLEMENT`
- `ADJACENT_TO_TRACK`
- `ROAD_ACCESS`
- `FREIGHT_FACILITY_ON_TRACK`
- `WATER_CROSSED_BY_TRACK`
- `BRIDGE_CARRIES_TRACK`

The relation layer explains why track exists: a loading track serves a goods shed, a spur serves a grain store, a bridge carries the main over a creek.

## Governance Labels
Every future grammar rule should carry one label:

| Label | Meaning |
| --- | --- |
| `observed` | Explicitly present in corpus/source material. |
| `inferred` | Relationship inferred from multiple observations. |
| `design_prior` | Chosen before enough corpus frequency evidence exists. |
| `gameplay_abstraction` | Deliberate compression or departure for playability. |

## Runtime Rule
JSON is canonical for runtime and automated validation. YAML is permitted only as a human-readable reference copy.

## Sprint 9B Reference Archetypes
Sprint 9B uses authored semantic fixtures to prove the schema covers multiple materially different railway places through one immutable blueprint API:

| Archetype | Purpose |
| --- | --- |
| `rural_through` | Low-complexity countryside baseline with an entry, through main and exit. |
| `village_passing_station` | Small passenger stop with a double-ended passing loop and platform. |
| `small_town_goods_station` | Compact station with loop, goods yard, loading track and local industry. |
| `agricultural_loading_point` | Branch-line loading place where an agricultural spur serves a loading facility. |
| `river_valley_constrained` | Constrained station where railway and water relationships require a bridge/crossing relation. |
| `declining_abandoned_branch` | Freight-era decline fixture with storage/abandoned track semantics. |

These are not procedural outputs and do not contain physical rail geometry. They are canonical JSON reference data for testing the shared semantic contract.

Sprint 9A does not generate sectors. Sprint 9B also does not generate sectors; it proves authored semantic coverage before deterministic generation, geometry embedding and gameplay placement are attempted.

## Sprint 9C Semantic Validation
Sprint 9C rejects source-neutral semantic graphs that are operationally nonsensical before physical geometry exists.

Conservative 9C rules:
- active entry and exit must be connected through usable non-abandoned railway edges;
- `PASSING_LOOP` edges must be double-ended and reconnect to usable railway network at both ends;
- active dead-end tracks must terminate at meaningful terminal semantics such as `BUFFER_STOP`;
- yard and spur roles must connect to usable railway network;
- industry/agricultural spur service must be supported by existing `FREIGHT_FACILITY_ON_TRACK` relationships;
- bridge relations must correspond to an existing water-crossing relation on the same rail edge.

`ABANDONED_TRACK` remains valid semantic evidence for declining/disused archetypes, but it does not satisfy active movement or active-service validation.

## Sprint 9D Runtime Reconstruction Fixture
Sprint 9D adds one authored spatial embedding for `small_town_goods_station`.

The semantic fixture remains a source-neutral description of railway meaning. The embedding is a separate authored placement layer for one proof scene. It may realise one semantic junction as multiple ordinary physical turnouts when that better matches the current `RailMovement` runtime.

For the small-town goods station, the west semantic station throat is embedded as:
- a west yard turnout selecting main route or goods-yard lead;
- a short authored connector;
- a west loop turnout selecting platform main or passing loop.

This decomposition is runtime placement detail. It does not add new semantic ontology and does not imply a procedural spatial solver exists.

## Sprint 9E Multi-Archetype Runtime Reconstruction
Sprint 9E adds authored spatial embeddings for all six Sprint 9B reference archetypes and reconstructs each through the same runtime path.

The embedding layer remains separate from semantic meaning:
- semantic fixtures describe the railway/world graph;
- embeddings describe authored physical placement for reference layouts;
- `WorldgenRuntimeReconstructor` translates generic embedding data;
- `RailMovement` remains the live movement authority.

Route presets are development-harness convenience metadata only. They apply ordinary turnout settings and do not create a second routing system.

Declining/disused railway is represented by mapping `ABANDONED_TRACK` edges to display-only runtime segments. These segments are visible and retain semantic IDs, but they are excluded from active movement connections and cannot satisfy active routing.

## Sprint 9G Generated Village Passing Station
Sprint 9G generates one restrained semantic archetype: `village_passing_station`.

The generated railway grammar is:

```text
ENTRY
  -> approach main
  -> west loop switch
  -> station main or passing loop
  -> east loop switch
  -> exit main
  -> EXIT
```

The semantic graph always contains:
- one active entry-to-exit route;
- one double-ended `PASSING_LOOP`;
- station, platform and settlement entities;
- a `PLATFORM_SERVES_TRACK` relation targeting a usable active station track.

Allowed 9G variation is deliberately small:
- `topology` may choose whether the platform serves the station main or passing loop;
- `world_entities` may choose whether simple road access is present.

9G does not generate loop side, station side, physical road geometry, coordinates, goods yards, agricultural loading, river crossings or abandoned branches.
