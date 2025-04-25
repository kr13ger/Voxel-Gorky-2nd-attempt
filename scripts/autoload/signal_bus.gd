extends Node
# SignalBus.gd
# Location: res://scripts/autoload/signal_bus.gd
# Autoload name: SignalBus

# Dictionary to track registered signals
var _registered_signals: Dictionary = {}

# Game state signals
signal game_started
signal game_paused
signal game_resumed
signal game_ended

# Vehicle signals
signal vehicle_damaged(vehicle_id: int, damage_amount: float, hit_position: Vector3)
signal vehicle_destroyed(vehicle_id: int)
signal vehicle_component_damaged(vehicle_id: int, component_id: String, damage_amount: float)
signal vehicle_component_destroyed(vehicle_id: int, component_id: String)

# Weapon signals
signal weapon_fired(weapon_id: String, origin: Vector3, direction: Vector3)
signal weapon_reloading(weapon_id: String)
signal weapon_reloaded(weapon_id: String)
signal ammo_changed(weapon_id: String, current_ammo: int, max_ammo: int)

# Physics/Environment signals
signal object_hit(object_id: int, hit_position: Vector3, hit_force: float)
signal explosion_occurred(position: Vector3, radius: float, force: float)

func _ready() -> void:
	Logger.info("SignalBus initialized", "SignalBus")
	_register_built_in_signals()

# Register all built-in signals defined in this class
func _register_built_in_signals() -> void:
	var signal_list = get_signal_list()
	for signal_info in signal_list:
		_registered_signals[signal_info.name] = true
		Logger.debug("Registered built-in signal: %s" % signal_info.name, "SignalBus")

# Register a custom signal dynamically
func register_signal(signal_name: String) -> void:
	if _registered_signals.has(signal_name):
		Logger.warning("Signal '%s' already registered" % signal_name, "SignalBus")
		return
	
	# Add the signal to this object
	add_user_signal(signal_name)
	_registered_signals[signal_name] = true
	Logger.debug("Registered custom signal: %s" % signal_name, "SignalBus")

# Emit a signal by name with optional arguments
func emit_signal_by_name(signal_name: String, args: Array = []) -> void:
	if not _registered_signals.has(signal_name):
		Logger.error("Attempted to emit unregistered signal: %s" % signal_name, "SignalBus")
		return
	
	callv("emit_signal", [signal_name] + args)
	Logger.debug("Emitted signal: %s" % signal_name, "SignalBus")

# Check if a signal is registered
func is_signal_registered(signal_name: String) -> bool:
	return _registered_signals.has(signal_name)

# Get all registered signal names
func get_registered_signals() -> Array:
	return _registered_signals.keys()
