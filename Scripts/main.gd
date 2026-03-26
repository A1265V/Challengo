#Copyright [Year] [Your Name]
#Licensed under the PolyForm Noncommercial License 1.0.0
#See LICENSE file in the project root for full license terms.
extends Control

@onready var datelbl: Label = $Main/Topbar/Date
@onready var streak_bg: Sprite2D = $Main/Topbar/Streak/StreakBG
@onready var flame: Sprite2D = $Main/Topbar/Streak/Flame
@onready var streak_lbl: Label = $Main/Topbar/Streak/Streak
@onready var best: Label = $Main/Topbar/Streak/Best
@onready var habit_name_lbl: Label = $Main/Topbar/Streak/Name
@onready var button: TouchScreenButton = $Main/Button
@onready var habit_holder: VBoxContainer = $Add/HabitHolder
@onready var line_edit: LineEdit = $EnterHabitName/Edit
@onready var main: CanvasLayer = $Main
@onready var add: CanvasLayer = $Add
@onready var enter_habit_name: CanvasLayer = $EnterHabitName
@onready var edit: LineEdit = $EnterHabitName/Edit
@onready var datelbl2: Label = $Add/Topbar/Date
@onready var settings: CanvasLayer = $Settings

const inactive_fire := preload("res://Assets/flamegreyedout.svg")
const active_fire := preload("res://Assets/flame.svg")
const inactive_pill := preload("res://Assets/pill_streak_inactive.svg")
const active_pill := preload("res://Assets/pill_streak_active.svg")
const SAVE_PATH = "user://savegame.json"
const HabitScene = preload("res://Scenes/habit.tscn")

var opened_habit :int = -1
var data := {
	"habits": []
}

var default := {
	"habit_name": "",
	"streak": 0,
	"best": 0,
	"last_claim_unix": -1,
	"is_claimed": false,
}

func _ready() -> void:
	load_data()
	check_all_habits_time()
	get_habits()
	update_button()
	update_date_display()

func _on_add_pressed():
	enter_habit_name.visible = true
	edit.edit()

func _on_edit_text_submitted(text: String) -> void:
	var def = default.duplicate()
	def["habit_name"] = text
	data["habits"].append(def)
	save_data()
	enter_habit_name.visible = false
	edit.clear()
	clear_habits()
	get_habits()

func clear_habits():
	for c in habit_holder.get_children():
		c.queue_free()

func get_habits():
	for i in data.habits.size():
		var item = HabitScene.instantiate()
		item.habit_name = data.habits[i]["habit_name"]
		item.current_streak = data.habits[i]["streak"]
		item.is_claimed = data.habits[i]["is_claimed"]
		item.custom_minimum_size.y = 55
		item.habit_selected.connect(habit_select.bind(i))
		habit_holder.add_child(item)

func habit_select(idx :int):
	opened_habit = idx
	main.visible = true
	add.visible = false
	update_habit(idx)
	update_button()

func update_habit(idx :int):
	var habit = data.habits[idx]
	if habit["is_claimed"] == true:
		flame.texture = active_fire
		streak_bg.texture = active_pill
	else:
		flame.texture = inactive_fire
		streak_bg.texture = inactive_pill
	habit_name_lbl.text = habit["habit_name"]
	streak_lbl.text = str(habit["streak"])
	best.text = "Best Streak: " + str(int(habit["best"]))

func _on_button_pressed() -> void:
	if opened_habit == -1: return
	data.habits[opened_habit]["streak"] += 1
	data.habits[opened_habit]["is_claimed"] = true
	data.habits[opened_habit]["last_claim_unix"] = int(Time.get_unix_time_from_system())
	fix_best()
	save_data()
	update_habit(opened_habit)
	update_button()
	clear_habits()
	get_habits()

func fix_best():
	if data.habits[opened_habit]["streak"] > data.habits[opened_habit]["best"]:
		data.habits[opened_habit]["best"] = data.habits[opened_habit]["streak"]

func update_button():
	if opened_habit > -1:
		button.process_mode = PROCESS_MODE_DISABLED if data.habits[opened_habit]["is_claimed"] else PROCESS_MODE_INHERIT
		button.modulate = Color(0.5, 0.5, 0.5, 1) if data.habits[opened_habit]["is_claimed"] else Color(1, 1, 1, 1)
	else:
		button.process_mode = PROCESS_MODE_DISABLED

func _on_back_pressed() -> void:
	main.visible = false
	add.visible = true

func update_date_display() -> void:
	var date = Time.get_date_dict_from_system()
	var DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var MONTH_NAMES = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	var suffix = get_ordinal_suffix(date.day)
	var formatted = "%s, %d%s %s, %d" % [DAY_NAMES[date.weekday], date.day, suffix, MONTH_NAMES[date.month], date.year]
	datelbl.text = formatted
	datelbl2.text = formatted

func get_ordinal_suffix(day: int) -> String:
	if day >= 11 and day <= 13: return "th"
	match day % 10:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"

func get_day_start_unix(unix: int) -> int:
	var date = Time.get_datetime_dict_from_unix_time(unix)
	date.hour = 0
	date.minute = 0
	date.second = 0
	return Time.get_unix_time_from_datetime_dict(date)

func check_all_habits_time() -> void:
	var now_unix = int(Time.get_unix_time_from_system())
	var today_start = get_day_start_unix(now_unix)
	var changed = false
	for habit in data.habits:
		if habit["last_claim_unix"] == -1: continue
		var last_claim_start = get_day_start_unix(habit["last_claim_unix"])
		var diff = today_start - last_claim_start
		if diff >= 86400:
			if habit["is_claimed"]:
				habit["is_claimed"] = false
				changed = true
		if diff >= 172800:
			if habit["streak"] > 0:
				habit["streak"] = 0
				changed = true
	if changed:
		save_data()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data_string = JSON.stringify(data, "\t")
	file.store_string(data_string)

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		data = json.data

func _on_back_set_pressed() -> void:
	add.visible = true
	settings.visible = false

func _on_settings_pressed() -> void:
	add.visible = false
	settings.visible = true

func _on_clear_pressed() -> void:
	data.habits = []
	save_data()
	load_data()
