# Current Sprint — Sprint 0: Project Skeleton

**Status:** READY TO START

## Sprint objective
Establish a disciplined, runnable Godot project and Codex workflow before implementing gameplay systems.

## Hypothesis
A small, clean project skeleton with explicit scope rules will make subsequent prototype work faster and prevent scope creep/rabbit-hole development.

## In scope
- Detect and document installed Godot/Codex/Git versions.
- Confirm the Godot project opens/runs.
- Establish a minimal project directory structure based on actual usage.
- Add this documentation pack to the repository.
- Create a minimal `Main`/prototype scene if one does not exist.
- Add a simple visible build/project label to prove the scene launches.
- Add the simplest practical project validation command for the local environment.
- Add/update `.gitignore` for Godot-generated files as needed.
- Confirm Codex loads `AGENTS.md`.
- Create a clean Git checkpoint after validation.

## Out of scope
Do NOT implement:
- train movement;
- railway geometry;
- wagons/couplers;
- crew;
- inventory/resources;
- procedural generation;
- combat;
- final UI;
- final art;
- Google/Gemini image generation integration;
- plugins/addons unless required merely to run the existing project.

## Acceptance test
Sprint 0 is complete only when all are true:

- [ ] The Godot project launches a minimal prototype scene successfully.
- [ ] No known GDScript parser errors remain.
- [ ] `git status` is understood and unrelated user work is preserved.
- [ ] `AGENTS.md` and `docs/` are present in the repository.
- [ ] Codex can summarise the loaded project instructions and identify Sprint 0 as active.
- [ ] A repeatable validation command/process is recorded in `README.md` or this file.
- [ ] A Git checkpoint/commit exists for the completed skeleton unless the user explicitly declines committing.

## Definition of done
A runnable skeleton is more important than architectural completeness. Do not pre-build future systems.

## Next sprint
After Sprint 0 acceptance, replace this file's active content with Sprint 1 from `ROADMAP.md`: **Train Moves on Rails**.
