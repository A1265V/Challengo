extends Control

#region Nodes
@onready var datelbl: Label = $Main/Topbar/Date
@onready var streak_bg: Sprite2D = $Main/Topbar/Streak/StreakBG
@onready var flame: Sprite2D = $Main/Topbar/Streak/Flame
@onready var streak_lbl: Label = $Main/Topbar/Streak/Streak
@onready var best: Label = $Main/Topbar/Streak/Best
@onready var habit_name_lbl: Label = $Main/Topbar/Streak/Name
@onready var button: TouchScreenButton = $Main/Button
@onready var habit_holder: VBoxContainer = $Add/HabitHolder
@onready var main: CanvasLayer = $Main
@onready var add: CanvasLayer = $Add
@onready var enter_habit_name: CanvasLayer = $EnterHabitName
@onready var edit: LineEdit = $EnterHabitName/Edit
@onready var datelbl2: Label = $Add/Topbar/Date
@onready var settings: CanvasLayer = $Settings
@onready var total_: Label = $Main/Topbar/Streak/Total
@onready var delete_btn: TouchScreenButton = $Add/Delete
@onready var settings_btn: TouchScreenButton = $Add/Settings
#endregion

#region Assets
const inactive_fire := preload("res://Assets/flamegreyedout.svg")
const active_fire := preload("res://Assets/flame.svg")
const inactive_pill := preload("res://Assets/pill_streak_inactive.svg")
const active_pill := preload("res://Assets/pill_streak_active.svg")
#endregion

#region Constants
const SAVE_PATH = "user://savegame.json"
const HabitScene = preload("res://Scenes/habit.tscn")
#endregion

#region State
var opened_habit: int = -1      # index of the habit currently open in detail view, -1 if none
var button_selected: bool = false
var selected_habits: Array = [] # nodes currently selected for deletion
#endregion

#region Data
var data := { "habits": [] }

var default := {
	"habit_name": "",
	"streak": 0,
	"best": 0,
	"last_claim_unix": -1,
	"is_claimed": false,
	"total": 0,
}
#endregion


func _ready() -> void:
	delete_btn.visible = false
	delete_btn.pressed.connect(_on_delete_pressed)
	load_data()
	check_all_habits_time()
	get_habits()
	update_button()
	update_date_display()


#region Scene navigation
func _on_add_pressed() -> void:
	enter_habit_name.visible = true
	edit.edit()

func _on_back_pressed() -> void:
	main.visible = false
	add.visible = true

func _on_settings_pressed() -> void:
	add.visible = false
	settings.visible = true

func _on_back_set_pressed() -> void:
	add.visible = true
	settings.visible = false

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if enter_habit_name.visible:
		# Dismiss name input and return to habit list
		enter_habit_name.visible = false
		add.visible = true
	elif button_selected:
		# Cancel multi-select mode without deleting
		for node in selected_habits:
			node.button_unselect()
		selected_habits.clear()
		button_selected = false
		delete_btn.visible = false
		settings_btn.visible = true
	elif not add.visible:
		# Return to habit list from detail or settings view
		add.visible = true
		settings.visible = false
		main.visible = false
	else:
		get_tree().quit()
#endregion


#region Habit list
func get_habits() -> void:
	for i in data.habits.size():
		var item = HabitScene.instantiate()
		item.habit_name = data.habits[i]["habit_name"]
		item.current_streak = data.habits[i]["streak"]
		item.is_claimed = data.habits[i]["is_claimed"]
		item.index = i
		item.custom_minimum_size.y = 55
		item.habit_selected.connect(habit_select.bind(i))
		item.button_selected.connect(habit_toggle_select)
		habit_holder.add_child(item)

func clear_habits() -> void:
	for c in habit_holder.get_children():
		c.queue_free()
#endregion


#region Multi-select and deletion
func habit_toggle_select(node) -> void:
	# Add to selection if not already selected, otherwise deselect it
	if node in selected_habits:
		selected_habits.erase(node)
		node.button_unselect()
	else:
		selected_habits.append(node)
	button_selected = selected_habits.size() > 0
	delete_btn.visible = button_selected
	settings_btn.visible = not button_selected

func _on_delete_pressed() -> void:
	# Collect indices from selected nodes before freeing them
	var indices: Array = []
	for node in selected_habits:
		indices.append(node.index)
		node.queue_free()
	# Remove highest indices first so earlier indices don't shift during removal
	indices.sort()
	indices.reverse()
	for idx in indices:
		data.habits.remove_at(idx)
	selected_habits.clear()
	button_selected = false
	delete_btn.visible = false
	settings_btn.visible = true
	save_data()
#endregion


#region Habit detail view
func habit_select(idx: int) -> void:
	opened_habit = idx
	main.visible = true
	add.visible = false
	update_habit(idx)
	update_button()

func update_habit(idx: int) -> void:
	var habit = data.habits[idx]
	flame.texture = active_fire if habit["is_claimed"] else inactive_fire
	streak_bg.texture = active_pill if habit["is_claimed"] else inactive_pill
	habit_name_lbl.text = habit["habit_name"]
	streak_lbl.text = str(int(habit["streak"]))
	best.text = "Best Streak: " + str(int(habit["best"])) + " days"
	total_.text = "Total: " + str(int(habit["total"])) + " days"

func _on_button_pressed() -> void:
	if opened_habit == -1:
		return
	data.habits[opened_habit]["streak"] += 1
	data.habits[opened_habit]["is_claimed"] = true
	data.habits[opened_habit]["last_claim_unix"] = int(Time.get_unix_time_from_system())
	fix_best()
	total()
	save_data()
	update_habit(opened_habit)
	update_button()
	clear_habits()
	get_habits()

func update_button() -> void:
	if opened_habit > -1:
		var claimed = data.habits[opened_habit]["is_claimed"]
		button.process_mode = PROCESS_MODE_DISABLED if claimed else PROCESS_MODE_INHERIT
		button.modulate = Color(0.5, 0.5, 0.5, 1) if claimed else Color(1, 1, 1, 1)
	else:
		button.process_mode = PROCESS_MODE_DISABLED

func fix_best() -> void:
	if data.habits[opened_habit]["streak"] > data.habits[opened_habit]["best"]:
		data.habits[opened_habit]["best"] = data.habits[opened_habit]["streak"]

func total() -> void:
	data.habits[opened_habit]["total"] += 1
#endregion


#region Date display
func update_date_display() -> void:
	var date = Time.get_date_dict_from_system()
	var DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var MONTH_NAMES = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	var suffix = get_ordinal_suffix(date.day)
	datelbl.text = "%s, %d%s %s, %d" % [DAY_NAMES[date.weekday], date.day, suffix, MONTH_NAMES[date.month], date.year]
	datelbl2.text = datelbl.text

func get_ordinal_suffix(day: int) -> String:
	if day >= 11 and day <= 13:
		return "th"
	match day % 10:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"
#endregion


#region Streak time checks
func check_all_habits_time() -> void:
	# Run on startup to reset claims/streaks for habits missed since last open
	var today_start = get_day_start_unix(int(Time.get_unix_time_from_system()))
	var changed = false
	for habit in data.habits:
		if habit["last_claim_unix"] == -1:
			continue
		var diff = today_start - get_day_start_unix(habit["last_claim_unix"])
		if diff >= 86400 and habit["is_claimed"]:
			# A new day has started — unclaim so the habit can be done again
			habit["is_claimed"] = false
			changed = true
		if diff >= 172800 and habit["streak"] > 0:
			# Two or more days missed — streak is broken
			habit["streak"] = 0
			changed = true
	if changed:
		save_data()

func get_day_start_unix(unix: int) -> int:
	# Snap a unix timestamp to midnight of its day for clean day comparison
	var date = Time.get_datetime_dict_from_unix_time(unix)
	date.hour = 0
	date.minute = 0
	date.second = 0
	return Time.get_unix_time_from_datetime_dict(date)
#endregion


#region Save / Load
func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		data = json.data

func _on_clear_pressed() -> void:
	data.habits = []
	save_data()
	load_data()
#endregion
