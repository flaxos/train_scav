# Worldgen Source Register

## Raw Research Inputs
- `docs/deep-research-report-grammer.md`
- `docs/deep-research-report-prompts.md`

These files are raw reference inputs. They are intentionally broader than the active sprint and should not be treated as automatic implementation scope.

## Curated Runtime Inputs
- `data/worldgen/schema/semantic_graph_v1.schema.json`
- `data/worldgen/archetypes/central_eu_small_town_station_v1.json`
- `data/worldgen/tests/test_seeds_v1.json`

These files are the Sprint 9A canonical data inputs.

## Human Reference Inputs
- `data/worldgen/archetypes/central_eu_small_town_station_v1.yaml`

This file is for authoring/review only. Godot runtime and tests should consume JSON.

## Source Mapping Rule
External source terms may appear in research/corpus notes, but runtime fixtures use internal roles:

| External hint | Internal role candidates |
| --- | --- |
| OSM/ORM through or branch railway | `THROUGH_MAIN` |
| OSM/ORM siding/passing context | `PASSING_LOOP`, `PLATFORM_TRACK` |
| OSM/ORM yard/manipulation context | `GOODS_YARD_TRACK`, `LOADING_TRACK`, `STORAGE_TRACK` |
| OSM/ORM industrial spur context | `INDUSTRIAL_SPUR`, `AGRICULTURAL_SPUR` |
| Lifecycle/disused/abandoned evidence | `ABANDONED_TRACK` |

The mapping is research provenance, not runtime authority.
