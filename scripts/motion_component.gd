extends Node

@export var last_position = Vector2.ZERO
@export var last_linear_velocity = Vector2.ZERO
@export var last_rotation = 0.0
@export var last_angular_velocity = 0.0
@export var last_update_time = 0.0
var sync_time = 0.03

func _ready():
	pass

func _process(delta):
	var p = get_parent()
	if multiplayer.get_unique_id() == 1:
		last_linear_velocity = p.linear_velocity
		last_position = p.position
		last_rotation = p.rotation
		last_angular_velocity = p.angular_velocity
	else:
		var time_since_last_update = Time.get_ticks_msec() - last_update_time
		var predicted_position = last_position + last_linear_velocity * (time_since_last_update/1000.0)
		var predicted_rotation = last_rotation + last_angular_velocity * (time_since_last_update/1000.0)

		predicted_rotation = fmod(predicted_rotation, 2 * PI)
		
		var perc = (delta/sync_time)
		# From start_pos and start_rot to predicted, get perc percent along the line between
		var new_pos = (1.0-perc)*p.position + perc*predicted_position
		#var new_rot = (1.0-perc)*p.rotation + perc*predicted_rotation
		var new_rot = interpolate_rotation(p.rotation, predicted_rotation, perc)
		p.position = last_position #new_pos
		p.rotation = last_rotation #new_rot

func interpolate_rotation(start_rot, end_rot, perc):
	# Normalize rotations
	start_rot = fmod(start_rot, 2 * PI)
	end_rot = fmod(end_rot, 2 * PI)

	# Find the shortest path
	var difference = fmod(end_rot - start_rot, 2 * PI)
	if difference > PI:
		difference -= 2 * PI
	elif difference < -PI:
		difference += 2 * PI

	return start_rot + difference * perc

func _on_multiplayer_synchronizer_synchronized():
	_on_multiplayer_synchronizer_delta_synchronized()

func _on_multiplayer_synchronizer_delta_synchronized():
	last_update_time = Time.get_ticks_msec()
