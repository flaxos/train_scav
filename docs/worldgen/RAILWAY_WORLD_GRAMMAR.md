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

Sprint 9A does not generate sectors. It defines the semantic contracts that Sprint 9B-9D must obey.
