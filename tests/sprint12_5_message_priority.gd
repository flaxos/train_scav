extends SceneTree

# Sprint 12.5 — Message Priority Tests.
# Verifies that critical departure blockers outrank generic scenario/route
# selection status text, preventing the UX failure where "Route selected..."
# shadows "Departure blocked: Train mass 277t exceeds 250t limit".

const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 12.5 Message Priority Tests ---")
	test_departure_blocker_outranks_scenario_selection()
	test_modal_outranks_idle()
	test_recent_command_outranks_scenario()
	test_crew_feedback_outranks_objective()
	_finish()


func test_departure_blocker_outranks_scenario_selection() -> void:
	print("Testing departure blocker outranks scenario route selection...")
	var departure_blocker := "Departure blocked: Train mass 277.0t exceeds Direct Line limit (250.0t max)"
	var scenario_status := "Route selected by track branch: Direct route"
	var recent_command := ""
	var crew_feedback := ""
	var objective := "Choose an eligible route exit and depart"

	var message := OperationalUIPresenter.get_top_priority_status_message(
		departure_blocker,
		false,
		recent_command,
		crew_feedback,
		objective,
		scenario_status
	)

	_expect(message == departure_blocker, "departure blocker is NOT shadowed by scenario selection status")
	_expect(not message.begins_with("Route selected"), "message does not show lower-priority route selected text")


func test_modal_outranks_idle() -> void:
	print("Testing departure confirmation prompt outranks idle status...")
	var message := OperationalUIPresenter.get_top_priority_status_message(
		"",
		true, # confirmation modal open
		"",
		"",
		"Explore sector",
		"",
		"Ready"
	)
	_expect(message.contains("Confirm departure"), "confirmation prompt shown when modal open")


func test_recent_command_outranks_scenario() -> void:
	print("Testing recent action result outranks generic scenario text...")
	var command_result := "Points P2 changed to NORTH W"
	var scenario_status := "Entered Sector 1"
	var message := OperationalUIPresenter.get_top_priority_status_message(
		"",
		false,
		command_result,
		"",
		"Objective",
		scenario_status
	)
	_expect(message == command_result, "command feedback takes priority over scenario background status")


func test_crew_feedback_outranks_objective() -> void:
	print("Testing active crew feedback...")
	var crew_feedback := "Iris boarding Shunter S"
	var message := OperationalUIPresenter.get_top_priority_status_message(
		"",
		false,
		"",
		crew_feedback,
		"Objective",
		""
	)
	_expect(message == crew_feedback, "crew feedback displayed when active")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 12.5 message priority acceptance passed")
		quit(0)
	else:
		print("\nSprint 12.5 message priority acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
