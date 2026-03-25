extends Control

@onready var datelbl: Label = $Main/Topbar/Date
@onready var streak_bg: Sprite2D = $Main/Topbar/Streak/StreakBG
@onready var flame: Sprite2D = $Main/Topbar/Streak/Flame
@onready var streak_lbl: Label = $Main/Topbar/Streak/Streak
@onready var best: Label = $Main/Topbar/Streak/Best
@onready var button: TouchScreenButton = $Main/Button

const inactive_fire := preload("res://Assets/flamegreyedout.svg")
const active_fire := preload("res://Assets/flame.svg")
const inactive_pill := preload("res://Assets/pill_streak_inactive.svg")
const active_pill := preload("res://Assets/pill_streak_active.svg")
const SAVE_PATH = "user://savegame.data"

var data := {
	"streak": 0,
	"best": 0,
	"last_claim_unix": -1
}

func _ready() -> void:
	load_data()
	update_date_display()
	check_streak_reset()
	check_button_status()
	update_streak_visuals()

func update_date_display() -> void:
	var date = Time.get_date_dict_from_system()
	var DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"]
	var MONTH_NAMES = ["", "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"]
	var suffix = get_ordinal_suffix(date.day)
	datelbl.text = "%s, %d%s %s, %d" % [DAY_NAMES[date.weekday], date.day, suffix, MONTH_NAMES[date.month], date.year]

func get_ordinal_suffix(day: int) -> String:
	if day >= 11 and day <= 13: return "th"
	match day % 10:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"

func get_day_start_unix(unix: int) -> int:
	# Returns the unix timestamp of midnight (00:00:00) for the day of the given unix time
	var date = Time.get_datetime_dict_from_unix_time(unix)
	date.hour = 0
	date.minute = 0
	date.second = 0
	return Time.get_unix_time_from_datetime_dict(date)

func check_streak_reset() -> void:
	if data.last_claim_unix == -1:
		return  # never claimed, nothing to reset

	var now_unix = int(Time.get_unix_time_from_system())
	var today_start = get_day_start_unix(now_unix)
	var last_claim_day_start = get_day_start_unix(data.last_claim_unix)
	var seconds_per_day = 86400

	# If last claim was before yesterday's start, streak is broken
	if today_start - last_claim_day_start > seconds_per_day:
		data.streak = 0
		save_data()

func check_button_status() -> void:
	if data.last_claim_unix == -1:
		button.set_deferred("disabled", false)
		return

	var now_unix = int(Time.get_unix_time_from_system())
	var today_start = get_day_start_unix(now_unix)
	var last_claim_day_start = get_day_start_unix(data.last_claim_unix)

	# Disable if already claimed today
	if (today_start == last_claim_day_start):
		button.set_deferred("disabled", true)

func _on_button_pressed() -> void:
	var now_unix = int(Time.get_unix_time_from_system())
	var today_start = get_day_start_unix(now_unix)

	# Safety: don't allow double claim on same day
	if data.last_claim_unix != -1:
		var last_claim_day_start = get_day_start_unix(data.last_claim_unix)
		if today_start == last_claim_day_start:
			return

	data.streak += 1
	data.last_claim_unix = now_unix

	if data.streak > data.best:
		data.best = data.streak

	save_data()
	update_streak_visuals()
	button.set_deferred("disabled", true)

func update_streak_visuals() -> void:
	streak_lbl.text = str(data.streak)
	best.text = "Best Streak: " + str(data.best) + " days"
	if data.streak > 0:
		streak_bg.texture = active_pill
		flame.texture = active_fire
	else:
		streak_bg.texture = inactive_pill
		flame.texture = inactive_fire

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var loaded = file.get_var()
			for key in loaded.keys():
				data[key] = loaded[key]
			file.close()
	# Migrate old saves that used last_claim_day (int day number) instead of unix
	if data.has("last_claim_day"):
		data.erase("last_claim_day")
		if not data.has("last_claim_unix"):
			data["last_claim_unix"] = -1
		save_data()
