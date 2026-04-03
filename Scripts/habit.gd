extends Control

#region Nodes
@onready var habit: TouchScreenButton = $Habit
@onready var habit_name_lbl: Label = $Name
@onready var streak_bg: Sprite2D = $StreakBG
@onready var flame: Sprite2D = $Flame
@onready var streak_lbl: Label = $Streak
@onready var press_timer: Timer = $PressTimer
@onready var check_box: CheckBox = $CheckBox
#endregion

#region Assets
const inactive_fire := preload("res://Assets/flamegreyedout.svg")
const active_fire := preload("res://Assets/flame.svg")
const inactive_pill := preload("res://Assets/pill_streak_inactive.svg")
const active_pill := preload("res://Assets/pill_streak_active.svg")
#endregion

#region State
var habit_name: String = ""
var current_streak: int = 0
var is_claimed: bool = false
var index: int = -1
#endregion

#region Signals
signal habit_selected()       # emitted on short press — opens habit detail view
signal button_selected(node)  # emitted on long press — enters multi-select mode
#endregion


func _ready() -> void:
	# Wire signals not connected in the scene
	habit.released.connect(_on_habit_released)
	press_timer.timeout.connect(_on_press_timer_timeout)
	press_timer.one_shot = true
	update()


#region Input — press vs long press detection
func _on_habit_pressed() -> void:
	press_timer.start()

func _on_habit_released() -> void:
	# If timer is still running it was a short press, stop it and open the habit
	if press_timer.time_left > 0:
		press_timer.stop()
		emit_signal("habit_selected")

func _on_press_timer_timeout() -> void:
	# Long press confirmed — shrink and shift button to reveal checkbox, notify parent
	habit.scale.x = 0.82
	habit.position.x = 40
	habit_name_lbl.position.x = 60
	check_box.visible = true
	emit_signal("button_selected", self)
#endregion


#region UI update
func update() -> void:
	habit_name_lbl.text = habit_name
	streak_lbl.text = str(current_streak)
	if is_claimed:
		streak_bg.texture = active_pill
		flame.texture = active_fire
	else:
		streak_bg.texture = inactive_pill
		flame.texture = inactive_fire

func button_unselect() -> void:
	# Called by parent to deselect this habit — restore original button size and position
	habit.scale.x = 1.0
	habit.position.x = 0
	habit_name_lbl.position.x = 12
	check_box.visible = false
#endregion
