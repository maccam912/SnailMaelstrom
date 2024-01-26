extends Node

@export var address = "wss://snail.koski.co/ws";
@export var port = 8910;
@export var i = 1;

var connected_peer_ids = []
var peer = WebSocketMultiplayerPeer.new()

var player_scenes = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().root.set_multiplayer_authority(1)
	if DisplayServer.get_name() == "headless":
		print("We're headless! Start server.")
		call_deferred("start_server")
	else:
		print("We're not headless, be a client")
		call_deferred("start_client")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func start_server():
	var err = peer.create_server(port)

	if err != OK:
		print(err)
		return
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server is up and running.")
	call_deferred("spawn_props")

func spawn_props():
	var current_scene = get_tree().get_current_scene()
	var spawner: MultiplayerSpawner = current_scene.get_node("PropSpawner")
	var props_container = current_scene.get_node("Props")
	for i in range(spawner.get_spawnable_scene_count()):
		var res_path = spawner.get_spawnable_scene(i)
		var res = load(res_path)
		var scene = res.instantiate()
		scene.set_multiplayer_authority(1)
		var x = 200*i+200
		print(x)
		scene.position = Vector2(x, 250)
		if props_container:
			props_container.add_child(scene, true)
		else:
			printerr("No props container!")

func start_client():
	var err = peer.create_client(address)
	if err != OK:
		print(err)
		return
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(new_peer_id : int) -> void:
	print("Player " + str(new_peer_id) + " is joining...")
	# The connect signal fires before the client is added to the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout
	add_player(new_peer_id)

# Improved add_player function for multiplayer
func add_player(new_peer_id: int) -> void:
	# Add new peer ID to the list of connected peers
	connected_peer_ids.append(new_peer_id)

	# Preload the player scene
	var player_scene = preload("res://scenes/player.tscn")

	# Instantiate the player scene
	var new_player = player_scene.instantiate()
	new_player.set_multiplayer_authority(1)
	# Set an initial position for the new player
	var spawn = get_tree().root.get_node("/root/Stage/Spawn")
	var spawn_loc = spawn.position
	print("Moved to spawn loc")
	new_player.position = spawn_loc

	# Set the network master for the new player instance
	new_player.player_id = new_peer_id

	var current_scene = get_tree().get_current_scene()
	var players_container = current_scene.get_node("Players")
	
	if players_container:
		players_container.add_child(new_player, true)
	else:
		printerr("Players container node not found")

	# Debugging prints for server-side confirmation
	print("Player " + str(new_peer_id) + " spawned and added to the scene.")

	# Synchronize the player list across clients
	rpc("sync_player_list", connected_peer_ids)

	# More debugging information
	print("Currently connected players: " + str(connected_peer_ids))

	# Additional error checking for potential issues
	print("Network master for player " + str(new_peer_id) + " set to: " + str(new_player.get_multiplayer_authority()))
	player_scenes[new_peer_id] = new_player

	if not new_player.is_multiplayer_authority():
		printerr("Network master not set correctly for player: " + str(new_peer_id))

func _on_peer_disconnected(leaving_peer_id : int) -> void:
	# The disconnect signal fires before the client is removed from the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout 
	remove_player(leaving_peer_id)


func remove_player(leaving_peer_id : int) -> void:
	var current_scene = get_tree().get_current_scene()
	var players_container = current_scene.get_node("Players")

	if players_container:
		players_container.remove_child(player_scenes[leaving_peer_id])
	else:
		printerr("Players container node not found")
	player_scenes.erase(leaving_peer_id)
	var peer_idx_in_peer_list : int = connected_peer_ids.find(leaving_peer_id)
	if peer_idx_in_peer_list != -1:
		connected_peer_ids.remove_at(peer_idx_in_peer_list)
	print("Player " + str(leaving_peer_id) + " disconnected.")
	rpc("sync_player_list", connected_peer_ids)

@rpc
func sync_player_list(_updated_connected_peer_ids):
	pass # only implemented in client (but still has to exist here)

@rpc("any_peer")
func handle_input(action):
	var id = multiplayer.get_remote_sender_id()
	if not player_scenes.has(id):
		return

	var player: RigidBody2D = player_scenes[id]
	match action:
		"GoLeft":
			player.apply_central_force(Vector2(-500, 0))
		"GoRight":
			player.apply_central_force(Vector2(500, 0))
		"Jump":
			player.apply_central_impulse(Vector2(0, -500))
			print("gave player jump ", player)

