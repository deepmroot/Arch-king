extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options

# Called when the node enters the scene tree for the first time.



# Called every frame. 'delta' is the elapsed time since the previous frame.

	
func _ready():
	main_buttons.visible = true
	options.visible = false


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level.tscn")


func _on_option_2_pressed() -> void:
	main_buttons.visible = false
	options.visible = true


func _on_exit_3_pressed() -> void:
	get_tree().quit()


func _on_back_options_3_pressed() -> void:
	_ready()


func _on_audio_control_value_changed(value: float) -> void:
	pass # Replace with function body.
