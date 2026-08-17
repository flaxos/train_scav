# Art Pipeline — Future Work, Not Current Sprint

## Status
Design placeholder only. Do not implement during Sprint 0–2 unless explicitly promoted.

## Principle
AI-assisted art generation should be a **development-time content tool**, not a runtime gameplay dependency.

Desired pipeline:

```text
ART SPEC
  ↓
PROMPT / REFERENCE SET
  ↓
IMAGE GENERATION SERVICE
  ↓
RAW SOURCE ASSET
  ↓
LOCAL PROCESSING
  ↓
CROP / SCALE / MASK / SLICE / VALIDATE
  ↓
GODOT-READY ASSET
  ↓
REVIEW + COMMIT
```

## Why not wire generation directly into Godot runtime?
- inconsistent output;
- network dependency;
- cost/quotas;
- slower iteration at runtime;
- asset licensing/provenance review;
- difficult deterministic builds;
- art consistency;
- unnecessary coupling between game and vendor API.

## Asset grammar to define before production generation

### Camera
- top-down / 3-quarter orthographic-like 2D presentation;
- consistent orientation across all rolling stock.

### Scale
Define a single pixel/metre or pixel/reference dimension before production asset work.

### Rolling-stock deliverables
A production wagon may eventually need:
- exterior body;
- interior/cutaway;
- roof state if used;
- damage variants;
- thumbnail/icon;
- collision geometry metadata;
- walkable interior mask/markers;
- door/portal positions;
- front/rear coupler anchors;
- equipment/socket anchors.

### Environment
Regional art sets should share:
- track scale;
- lighting convention;
- weatherability;
- damage/wear language;
- readable interactables.

## Google / Gemini experimentation
Google AI Studio or Gemini image-generation APIs may be evaluated later for concept and source-asset generation. Do not hard-code a specific model name into gameplay architecture. Keep provider-specific tooling isolated under `tools/` and treat generated outputs as imported source assets.

## Other tools
The pipeline should remain provider-agnostic enough to test alternative image-generation or conventional authored assets without reworking the game.
