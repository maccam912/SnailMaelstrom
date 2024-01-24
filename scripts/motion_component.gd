extends Node

@export var last_position = Vector2.ZERO
@export var last_rotation = 0.0
var last_update_time = 0.0
var sync_time = 60
var prev_position = Vector2.ZERO
var prev_rotation = 0.0
var prev2_position = Vector2.ZERO
var prev2_rotation = 0.0
func _ready():
	pass

func ease_in_out(start, end, t):
	var val = start + (end - start) * t
	return val

func ease_in_out_angle(start, end, t):
	var delta = fmod(end - start, 2*PI)
	if delta > PI:
		delta -= 2*PI
	elif delta < -PI:
		delta += 2*PI
	return start + delta * t
	
func _process(delta):
	var p = get_parent()
	if multiplayer.get_unique_id() == 1:
		last_position = p.position
		last_rotation = p.rotation
	else:
		var perc = 1.0*(Time.get_ticks_msec()-last_update_time)/sync_time
		p.position.x = ease_in_out(prev2_position.x, prev_position.x, min(perc, 1.0))
		p.position.y = ease_in_out(prev2_position.y, prev_position.y, min(perc, 1.0))
		p.rotation = ease_in_out_angle(prev2_rotation, prev_rotation, min(perc, 1.0))

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
	prev2_position = prev_position
	prev2_rotation = prev_rotation
	prev_position = last_position
	prev_rotation = last_rotation
	last_update_time = Time.get_ticks_msec()
