extends Control

@onready var datelbl: Label = $Main/Topbar/Date
@onready var streak_bg: Sprite2D = $Main/Topbar/Streak/StreakBG
@onready var flame: Sprite2D = $Main/Topbar/Streak/Flame
@onready var streak_lbl: Label = $Main/Topbar/Streak/Streak
@onready var button: TouchScreenButton = $Main/Button

const inactive_fire := preload("res://Assets/flamegreyedout.svg")
const active_fire := preload("res://Assets/flame.svg")
const inactive_pill := preload("res://Assets/pill_streak_inactive.svg")
const active_pill := preload("res://Assets/pill_streak_active.svg")
const SAVE_PATH = "user://savegame.data"

var data := {
	"streak" : 0,
	"best" : 0,
	"last_claim_day" : -1
}

func _ready() -> void:
	# ALWAYS load first, then update visuals
	load_data() 
	update_date_display()
	check_button_status()
	update_streak_visuals()

func update_date_display():
	var date = Time.get_date_dict_from_system()
	var DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"]
	var MONTH_NAMES = ["","January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	
	var suffix = get_ordinal_suffix(date.day)
	datelbl.text = "%s, %d%s %s, %d" % [DAY_NAMES[date.weekday], date.day, suffix, MONTH_NAMES[date.month], date.year]

func get_ordinal_suffix(day: int) -> String:
	if day >= 11 and day <= 13: return "th"
	match day % 10:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"

func check_button_status():
	var current_day = Time.get_date_dict_from_system().day
	if data.last_claim_day == current_day:
		button.hide()
	else:
		button.show()

func _on_button_pressed() -> void:
	var current_day = Time.get_date_dict_from_system().day
	
	# Safety check: don't increment if they somehow click twice
	if data.last_claim_day != current_day:
		data.streak += 1
		data.last_claim_day = current_day
		
		# Check for new best
		if data.streak > data.best:
			data.best = data.streak
			
		save_data()
		update_streak_visuals()
		button.hide()

func update_streak_visuals():
	streak_lbl.text = str(data.streak)
	if data.streak > 0:
		streak_bg.texture = active_pill
		flame.texture = active_fire
	else:
		streak_bg.texture = inactive_pill
		flame.texture = inactive_fire

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var loaded_data = file.get_var()
			# This merge ensures that if you add new keys later, old saves don't break
			for key in loaded_data.keys():
				data[key] = loaded_data[key]
			file.close()
