extends Component
# Weapon.gd
# Location: res://scripts/components/weapon.gd
# Base class for all weapon components

class_name Weapon

# Weapon properties
@export_group("Weapon Properties")
@export var damage: float = 50.0
@export var fire_rate: float = 1.0  # Rounds per second
@export var muzzle_velocity: float = 500.0  # m/s
@export var spread: float = 0.01  # Radians
@export var max_range: float = 1000.0  # Maximum effective range in meters
@export var projectile_scene: PackedScene = null  # Scene to spawn as projectile

# Ammunition properties
@export_group("Ammunition")
@export var magazine_size: int = 30
@export var reload_time: float = 3.0  # Seconds
@export var unlimited_ammo: bool = false

# Firing points
@export_group("Firing Points")
@export var muzzle_point: Node3D = null

# Current state
var current_ammo: int = 0
var total_ammo: int = 0
var is_reloading: bool = false
var time_since_last_shot: float = 0.0

# Signals
signal ammo_changed(current: int, total: int)
signal weapon_fired(position: Vector3, direction: Vector3)
signal reload_started()
signal reload_completed()

func _ready() -> void:
	super._ready()
	
	# Initialize ammo
	current_ammo = magazine_size
	total_ammo = unlimited_ammo ? -1 : magazine_size * 5  # Default 5 magazines
	
	if not muzzle_point:
		Logger.warning("Weapon has no muzzle point defined", "Weapon")
	
	Logger.info("Weapon initialized: %s (ID: %s)" % [display_name, component_id], "Weapon")
	Logger.debug("Weapon ammo: %d/%d" % [current_ammo, total_ammo], "Weapon")

func _process(delta: float) -> void:
	if is_destroyed:
		return
	
	time_since_last_shot += delta
	
	if is_reloading:
		# Handle reload timer here or in a separate function
		pass

# Fire the weapon
func fire() -> bool:
	if is_destroyed or is_reloading or current_ammo <= 0:
		if current_ammo <= 0 and not is_reloading:
			reload()
		return false
	
	# Check if we can fire based on fire rate
	if time_since_last_shot < 1.0 / fire_rate:
		return false
	
	# Reset fire timer
	time_since_last_shot = 0.0
	
	# Reduce ammo
	current_ammo -= 1
	emit_signal("ammo_changed", current_ammo, total_ammo)
	
	# Handle actual firing
	_spawn_projectile()
	
	# Emit signals
	emit_signal("weapon_fired", muzzle_point.global_position, muzzle_point.global_transform.basis.z.normalized())
	SignalBus.emit_signal("weapon_fired", component_id, muzzle_point.global_position, muzzle_point.global_transform.basis.z.normalized())
	
	Logger.debug("Weapon fired: %s, Ammo: %d/%d" % [display_name, current_ammo, total_ammo], "Weapon")
	
	# Auto-reload if empty
	if current_ammo <= 0:
		reload()
	
	return true

# Reload the weapon
func reload() -> bool:
	if is_destroyed or is_reloading or current_ammo >= magazine_size:
		return false
	
	# If unlimited ammo or we have ammo left
	if unlimited_ammo or total_ammo > 0:
		is_reloading = true
		
		# Emit signals
		emit_signal("reload_started")
		SignalBus.emit_signal("weapon_reloading", component_id)
		
		Logger.debug("Weapon reloading: %s" % display_name, "Weapon")
		
		# Start reload timer
		await get_tree().create_timer(reload_time).timeout
		
		if is_destroyed:
			is_reloading = false
			return false
		
		# Calculate how much ammo to add
		var ammo_to_add = magazine_size - current_ammo
		
		if not unlimited_ammo:
			# Limit by available total ammo
			ammo_to_add = min(ammo_to_add, total_ammo)
			total_ammo -= ammo_to_add
		
		current_ammo += ammo_to_add
		is_reloading = false
		
		# Emit signals
		emit_signal("reload_completed")
		emit_signal("ammo_changed", current_ammo, total_ammo)
		SignalBus.emit_signal("weapon_reloaded", component_id)
		SignalBus.emit_signal("ammo_changed", component_id, current_ammo, total_ammo)
		
		Logger.debug("Weapon reloaded: %s, Ammo: %d/%d" % [display_name, current_ammo, total_ammo], "Weapon")
		
		return true
	
	return false

# Spawn a projectile
func _spawn_projectile() -> void:
	if not projectile_scene or not muzzle_point:
		return
	
	# Instance the projectile
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	# Position the projectile at the muzzle
	projectile.global_transform = muzzle_point.global_transform
	
	# Apply spread
	if spread > 0:
		var random_spread = Vector3(
			randf_range(-spread, spread),
			randf_range(-spread, spread),
			0
		)
		projectile.global_transform.basis = projectile.global_transform.basis.rotated(Vector3.RIGHT, random_spread.x)
		projectile.global_transform.basis = projectile.global_transform.basis.rotated(Vector3.UP, random_spread.y)
	
	# Set projectile properties
	if projectile.has_method("initialize"):
		projectile.initialize(muzzle_velocity, damage, max_range)

# Add ammo to the weapon
func add_ammo(amount: int) -> void:
	if unlimited_ammo:
		return
	
	total_ammo += amount
	emit_signal("ammo_changed", current_ammo, total_ammo)
	
	Logger.debug("Added ammo to weapon: %s, Ammo: %d/%d" % [display_name, current_ammo, total_ammo], "Weapon")

# Get the current ammo percentage
func get_ammo_percentage() -> float:
	return float(current_ammo) / float(magazine_size) * 100.0

# Cancel a reload in progress
func cancel_reload() -> void:
	if is_reloading:
		is_reloading = false
		Logger.debug("Weapon reload canceled: %s" % display_name, "Weapon")
