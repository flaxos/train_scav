# Current Sprint — Sprint 7: Scavenging / Resources

**Status:** IMPLEMENTED FOR AUTOMATED VALIDATION — HUMAN PLAYTEST PENDING

## Hypothesis
Stopping the train becomes a meaningful strategic decision when useful resources exist outside the train, survivors must physically retrieve them, and time spent stopped has a real colony cost.

Core loop to prove:

TRAVEL -> STOP -> SELECT EXPEDITION -> LEAVE TRAIN -> SEARCH POI -> DISCOVER RESOURCE -> PICK UP / CARRY -> RETURN TO TRAIN -> DEPOSIT -> RETURN CREW -> DEPART SECTOR -> SUSTAIN THE TRAIN

Roadmap acceptance:
> The player must stop, search, retrieve a required resource, return the team, and depart to sustain the train.

## Baseline Dependency
Sprint 7 builds on the completed Sprint 6/6B sector lifecycle:
- sector container and current-sector identity;
- forward-only entry/exit transition;
- persistent train and crew transfer;
- old-sector disposal and no return;
- deterministic next-sector creation;
- run journal / transition metadata.

Do not create a second sector lifecycle for scavenging.

## In-Scope Behaviour
1. Add a train-level stockpile containing `DIESEL`, `FOOD`, and `PARTS`.
2. Add deterministic sector-local POIs: fuel depot, maintenance shed, and supply store.
3. Allow a selected survivor to search a POI through the existing physical crew task system.
4. Searching reveals deterministic loot at the POI but does not add it to the train.
5. Allow a survivor to physically pick up discovered loot and haul it to the train storage/deposit point.
6. Deposit transfers ownership into the train stockpile and clears carried cargo.
7. Sector elapsed time advances while stopped/searching; survivor needs continue updating.
8. Departing a sector requires and consumes a fixed diesel amount.
9. Departure is blocked if diesel is insufficient.
10. Departure is blocked while any expedition survivor is outside the train.
11. The playable scene exposes resources, POI state, survivor task/cargo state, and departure feedback through the existing side UI and right-click menu pattern.

## Authority Rules
- **Train/colony owns stockpiled resources** after deposit.
- **Sector/world owns POIs, searched state, uncollected loot, and elapsed sector time.**
- **Crew owns survivor position, tasks, and carried cargo.**
- **Sprint 6 lifecycle owns departure, old-sector disposal, persistent transfer, and next-sector creation.**

Searching discovers resources. Deposit transfers resources. No code path may add POI loot directly to the train without physical hauling.

## Explicit Exclusions
Do NOT implement in Sprint 7:
- combat, enemies, weapons, stealth, or random encounters;
- procedural towns/cities or deep loot tables;
- detailed inventory, weight, backpacks, or equipment;
- crafting, recipes, farming, trading, factions, economy;
- temperature/weather survival;
- new railway mechanics or multiple independent trains;
- save/load;
- final art or audio polish.

## Automated Acceptance
- [x] Resource store supports diesel/food/parts, add, consume, affordability, and non-negative clamping.
- [x] Active sector exposes deterministic POIs with stable state and one-time search yields.
- [x] Search requires a valid survivor task and completes only after physical arrival/interact time.
- [x] Scavenging skill affects search speed without making the Scavenger role mandatory.
- [x] Search discovers loot without changing train resources.
- [x] Hauling transfers loot from POI to survivor, then from survivor to train only on deposit.
- [x] Sector elapsed time and survivor needs advance during stopped expedition time.
- [x] Insufficient diesel blocks departure.
- [x] Outside crew blocks departure.
- [x] Hauled diesel can satisfy departure.
- [x] Successful departure consumes diesel and preserves Sprint 6 sector disposal/transfer semantics.
- [x] Existing Sprint 1-6 regression tests must remain green.

## Human Playtest Gate
Sprint 7 is not complete until the following is verified in the Godot GUI:
1. Start in Sector 0 with insufficient diesel to depart.
2. Attempt departure and confirm it is blocked by diesel.
3. Select Nia or another survivor.
4. Right-click Fuel Depot and assign Search.
5. Watch the survivor leave the train and walk to the POI.
6. Confirm search takes time and reveals diesel at the POI.
7. Confirm train diesel has not changed yet.
8. Right-click Fuel Depot and assign Haul.
9. Watch the survivor carry diesel back to B storage.
10. Confirm deposit increases train diesel and clears survivor cargo.
11. Board all outside expedition crew.
12. Depart the sector and confirm diesel is consumed.
13. Confirm the persistent train enters the next sector and the old sector is unavailable.

## Definition of Done
Sprint 7 is complete only after automated validation passes and the human playtest gate above is accepted by the user.

## Next Possible Increment
Sprint 8 — first vertical slice.
