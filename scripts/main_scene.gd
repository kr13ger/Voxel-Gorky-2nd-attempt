extends Node3D
# MainScene.gd
# Location: res://scripts/main_scene.gd
# Main scene controller script

# References
@export var player_vehicle_path: NodePath
var player_vehicle: PlayerVehicle = null

func _ready() -> void:
	Logger.info("Main scene initializing", "MainScene")
	
	# Get player vehicle reference
	if not player_vehicle_path.is_empty():
		player_vehicle = get_node(player_vehicle_path)
		if not player_vehicle:
			Logger.error("Failed to find player vehicle", "MainScene")
	
	# Set up physics environment
	_setup_environment()
	
	# Connect signals
	_connect_signals()
	
	Logger.info("Main scene ready", "MainScene")

func _setup_environment() -> void:
	# Set physics parameters
	Physics.set_gravity(Vector3(0, -9.8, 0))
	
	# Adjust physics settings for better vehicle simulation
	ProjectSettings.set_setting("physics/3d/default_contact_bias", 0.0001)
	ProjectSettings.set_setting("physics/3d/solver/contact_max_separation", 0.05)
	ProjectSettings.set_setting("physics/3d/solver/contact_max_allowed_penetration", 0.01)
	
	Logger.debug("Environment physics configured", "MainScene")

func _connect_signals() -> void:
	# Connect to vehicle signals
	SignalBus.connect("vehicle_destroyed", _on_vehicle_destroyed)
	SignalBus.connect("vehicle_damaged", _on_vehicle_damaged)
	
	# Connect to weapon signals
	SignalBus.connect("weapon_fired", _on_weapon_fired)
	
	Logger.debug("Signals connected", "MainScene")

func _process(delta: float) -> void:
	# Handle any per-frame updates
	pass

func _input(event: InputEvent) -> void:
	# Handle global input here
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

# Signal handlers
func _on_vehicle_destroyed(vehicle_id: int) -> void:
	if player_vehicle and vehicle_id == player_vehicle.get_instance_id():
		Logger.info("Player vehicle destroyed", "MainScene")
		# Handle player vehicle destruction (game over state, respawn, etc.)

func _on_vehicle_damaged(vehicle_id: int, damage_amount: float, hit_position: Vector3) -> void:
	# Handle vehicle damage (effects, UI updates, etc.)
	pass

func _on_weapon_fired(weapon_id: String, origin: Vector3, direction: Vector3) -> void:
	# Handle weapon firing (effects, sound, etc.)
	pass

# Game state functions
func _toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	
	if new_pause_state:
		Logger.debug("Game paused", "MainScene")
		SignalBus.emit_signal("game_paused")
	else:
		Logger.debug("Game resumed", "MainScene")
		SignalBus.emit_signal("game_resumed")

# Restart the current scene
func restart_scene() -> void:
	get_tree().reload_current_scene()
	Logger.info("Scene restarted", "MainScene")
