#Copyright [Year] [Your Name]
#Licensed under the PolyForm Noncommercial License 1.0.0
#See LICENSE file in the project root for full license terms.
extends Control

@onready var habit: TouchScreenButton = $Habit
@onready var habit_name_lbl: Label = $Name
@onready var streak_bg: Sprite2D = $StreakBG
@onready var flame: Sprite2D = $Flame
@onready var streak_lbl: Label = $Streak

const inactive_fire := preload("res://Assets/flamegreyedout.svg")
const active_fire := preload("res://Assets/flame.svg")
const inactive_pill := preload("res://Assets/pill_streak_inactive.svg")
const active_pill := preload("res://Assets/pill_streak_active.svg")

var habit_name: String = ""
var current_streak: int = 0
var is_claimed: bool = false
var index = -1

func _ready() -> void:
	update()

signal habit_selected(index)

func _on_habit_pressed() -> void:
	emit_signal("habit_selected")

func update():
	habit_name_lbl.text = habit_name
	streak_lbl.text = str(current_streak)
	if is_claimed == true:
		streak_bg.texture = active_pill
		flame.texture = active_fire
	else:
		streak_bg.texture = inactive_pill
		flame.texture = inactive_fire
		
	
