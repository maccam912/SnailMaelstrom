extends RigidBody2D

@export var player_id: int = 0;

func _enter_tree():
	get_tree().root.set_multiplayer_authority(1)

func _ready():
	if is_local_player():
		freeze = true
		var camera: Camera2D = get_node("Camera2D")
		camera.zoom = Vector2(2, 2)
		camera.set_enabled(true)

func is_local_player():
	var id = multiplayer.get_unique_id()
	return id == player_id

func _process(_delta):
	if Input.is_action_pressed("GoLeft"):
		Multiplayer.handle_input.rpc_id(1, "GoLeft")
	if Input.is_action_pressed("GoRight"):
		Multiplayer.handle_input.rpc_id(1, "GoRight")
	if Input.is_action_just_released("Jump"):
		Multiplayer.handle_input.rpc_id(1, "Jump")
	if Input.is_action_just_released("ZoomIn"):
		get_node("Camera2D").zoom *= 1.1
	if Input.is_action_just_released("ZoomOut"):
		get_node("Camera2D").zoom *= 0.9

func _on_jump_button_up():
	Input.action_press("Jump")
	Input.action_release("Jump")

func _on_left_button_down():
	Input.action_press("GoLeft")

func _on_left_button_up():
	Input.action_release("GoLeft")

func _on_right_button_down():
	Input.action_press("GoRight")

func _on_right_button_up():
	Input.action_release("GoRight")
