extends RigidBody2D

var last_update_time = 0;
var last_known_position = Vector2(0, 0);

# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer.get_unique_id() != 1:
		freeze = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
