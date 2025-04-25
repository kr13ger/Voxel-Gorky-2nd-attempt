extends Component
# Turret.gd
# Location: res://scripts/components/turret.gd
# Vehicle turret component

class_name Turret

# Turret properties
@export_group("Turret Properties")
@export var rotation_speed: float = 1.0  # Radians per second
@export var elevation_min: float = -0.1  # Radians
@export var elevation_max: float = 0.5   # Radians

# Weapon mount
@export_group("Weapon Mount")
@export var weapon_slot: Node3D = null
var attached_weapon: Component = null

# Current state
var current_rotation: float = 0.0
var current_elevation: float = 0.0
var target_rotation: float = 0.0
var target_elevation: float = 0.0
var is_rotating: bool = false

func _ready() -> void:
	super._ready()
	
	if not weapon_slot:
		Logger.warning("Turret has no weapon slot defined", "Turret")
	
	Logger.info("Turret initialized: %s (ID: %s)" % [display_name, component_id], "Turret")

func _process(delta: float) -> void:
	if is_destroyed:
		return
	
	if is_rotating:
		_update_rotation(delta)

# Rotate the turret towards a target position
func rotate_towards(target_position: Vector3) -> void:
	if is_destroyed:
		return
	
	# Convert target to local space
	var local_target = global_transform.inverse() * target_position
	
	# Calculate target rotation (yaw)
	target_rotation = atan2(local_target.x, local_target.z)
	
	# Calculate target elevation (pitch)
	var distance_xz = sqrt(local_target.x * local_target.x + local_target.z * local_target.z)
	target_elevation = atan2(-local_target.y, distance_xz)
	
	# Clamp elevation to valid range
	target_elevation = clamp(target_elevation, elevation_min, elevation_max)
	
	# Start rotation
	is_rotating = true

# Update the turret's rotation
func _update_rotation(delta: float) -> void:
	var rotation_step = rotation_speed * delta
	var elevation_step = rotation_speed * delta
	
	# Update yaw (turret rotation)
	var angle_diff = wrapf(target_rotation - current_rotation, -PI, PI)
	if abs(angle_diff) <= rotation_step:
		current_rotation = target_rotation
	else:
		current_rotation += sign(angle_diff) * rotation_step
	
	# Update pitch (gun elevation)
	angle_diff = target_elevation - current_elevation
	if abs(angle_diff) <= elevation_step:
		current_elevation = target_elevation
		is_rotating = false  # Stop rotating when target reached
	else:
		current_elevation += sign(angle_diff) * elevation_step
	
	# Apply rotation to the turret
	rotation.y = current_rotation
	
	# Apply elevation to the weapon if attached
	if attached_weapon and attached_weapon is Weapon:
		attached_weapon.rotation.x = current_elevation

# Attach a weapon to the turret
func attach_weapon(weapon: Component) -> bool:
	if not weapon_slot:
		Logger.error("No weapon slot available", "Turret")
		return false
	
	if not weapon is Weapon:
		Logger.error("Component is not a weapon", "Turret")
		return false
	
	# Parent the weapon to the slot
	if weapon.get_parent():
		weapon.get_parent().remove_child(weapon)
	weapon_slot.add_child(weapon)
	weapon.transform = Transform3D.IDENTITY
	
	# Store reference
	attached_weapon = weapon
	
	Logger.debug("Attached weapon: %s" % weapon.display_name, "Turret")
	return true

# Handle input for manual turret control
func handle_input(delta: float) -> void:
	if is_destroyed:
		return
	
	var rotation_input = Input.get_axis("turret_rotate_right", "turret_rotate_left")
	var elevation_input = Input.get_axis("turret_elevate_down", "turret_elevate_up")
	
	if rotation_input != 0 or elevation_input != 0:
		# Manual control overrides any ongoing rotation
		is_rotating = false
		
		# Update rotation
		current_rotation += rotation_input * rotation_speed * delta
		
		# Update elevation with clamping
		current_elevation += elevation_input * rotation_speed * delta
		current_elevation = clamp(current_elevation, elevation_min, elevation_max)
		
		# Apply rotation to the turret
		rotation.y = current_rotation
		
		# Apply elevation to the weapon if attached
		if attached_weapon and attached_weapon is Weapon:
			attached_weapon.rotation.x = current_elevation

# Fire the attached weapon
func fire() -> bool:
	if is_destroyed or not attached_weapon or not attached_weapon is Weapon:
		return false
	
	return attached_weapon.fire()

# Handle turret destruction
func _on_destroyed() -> void:
	# Disable rotation when destroyed
	is_rotating = false
	
	# Also damage the attached weapon if any
	if attached_weapon and not attached_weapon.is_destroyed:
		attached_weapon.take_damage(attached_weapon.max_health)
