# Design & Architecture Decision Log

Record decisions that would otherwise be repeatedly re-litigated. Keep entries concise.

## D-001 — Top-down 2D Godot
**Decision:** Build as a top-down 2D Godot 4.x game.  
**Reason:** Matches desired colony/railway visibility and keeps scope achievable.

## D-002 — Physical train
**Decision:** The train is a physical object/consist in the world rather than an abstract colony menu.  
**Reason:** Central product identity.

## D-003 — Real-time train movement
**Decision:** The train moves physically in real time.  
**Reason:** Travel, stopping, escape and railway operations need to feel continuous.

## D-004 — Physical shunting
**Decision:** Rolling stock cannot be click-drag reordered. Players use track, points, locomotives, crew and shunting operations.  
**Reason:** Defining mechanic and differentiator.

## D-005 — Forward-only sectors
**Decision:** Once the train exits a sector, the player can never return to it.  
**Reason:** Strong procedural-game identity, consequential decisions and simpler scalable simulation.

## D-006 — No simulation of departed sectors
**Decision:** Departed sectors are destroyed rather than simulated in the background.  
**Reason:** Nothing can return from them under current design; retaining simulation adds cost without gameplay benefit.

## D-007 — Persistent train, disposable world
**Decision:** Train/survivor/run state persists independently of sector scenes.  
**Reason:** Required by D-005 and D-006.

## D-008 — One community train
**Decision:** Core game centres on one train. Additional locomotives may later be added to that consist for push/pull/double-heading/shunting.  
**Reason:** Maintains intimacy and avoids fleet-management scope.

## D-009 — Crew automation
**Decision:** Survivors can be assigned roles/jobs that auto-create routine tasks.  
**Reason:** Allows detailed physical people without late-game micromanagement collapse.

## D-010 — Permadeath
**Decision:** Survivor death may be permanent.  
**Reason:** Skills and emergent history should create meaningful loss.

## D-011 — Failure by irrecoverable mobility/survival loss
**Decision:** A temporarily disabled locomotive is not automatically game over; irrecoverable loss of viable mobility/survival is.  
**Reason:** Recovery scenarios are more interesting than arbitrary HP thresholds.

## D-012 — Combat deferred
**Decision:** Combat is not required for the initial POC. Direction is lightweight click-to-engage/tactical commands, subject to later validation.  
**Reason:** Combat could consume the project before rail gameplay is proven.

## D-013 — Programmer art first
**Decision:** Early sprints use primitive/programmer art.  
**Reason:** Visual polish must not mask weak gameplay or block iteration.

## D-014 — AI art is an offline tool pipeline
**Decision:** Future generative art services produce source assets outside the runtime game. Godot consumes processed assets; the game does not depend on a live image-generation API.  
**Reason:** Reproducibility, cost, latency, licensing review, consistency and runtime reliability.
