extends Weapon
# AutoCannon.gd
# Location: res://scripts/components/auto_cannon.gd
# Auto cannon weapon for the BTR-82A

class_name AutoCannon

# Auto cannon specific properties
@export_group("Auto Cannon Properties")
@export var caliber: float = 30.0  # mm
@export var shell_weight: float = 0.39  # kg
@export var muzzle_flash_effect: PackedScene = null
@export var shell_ejection_effect: PackedScene = null
@export var recoil_distance: float = 0.1  # How far the gun recoils when fired
@export var recoil_recovery_speed: float = 5.0  # How quickly the gun returns to position

# Burst fire settings
@export_group("Burst Fire Settings")
@export var can_burst_fire: bool = true
@export var burst_size: int = 3
@export var burst_fire_rate_multiplier: float = 1.5  # Fires faster in burst mode

# Current state
var current_burst_count: int = 0
var is_in_burst_mode: bool = false
var original_position: Vector3
var current_recoil: float = 0.0

func _ready() -> void:
	super._ready()
	
	# Store original position for recoil effect
	original_position = position
	
	Logger.info("Auto cannon initialized: %s, Caliber: %.1fmm" % [display_name, caliber], "AutoCannon")

func _process(delta: float) -> void:
	super._process(delta)
	
	# Handle recoil recovery
	if current_recoil > 0:
		current_recoil = max(0, current_recoil - recoil_recovery_speed * delta)
		position.z = original_position.z - current_recoil
	
	# Handle burst fire
	if is_in_burst_mode and current_burst_count < burst_size:
		_handle_burst_fire()

# Override fire method to handle burst fire and recoil
func fire() -> bool:
	if is_destroyed or is_reloading or current_ammo <= 0:
		return false
	
	# Handle burst fire mode
	if can_burst_fire and is_in_burst_mode:
		# Use increased fire rate for burst
		if time_since_last_shot < 1.0 / (fire_rate * burst_fire_rate_multiplier):
			return false
	else:
		# Normal fire rate check
		if time_since_last_shot < 1.0 / fire_rate:
			return false
	
	# Apply recoil effect
	current_recoil = recoil_distance
	position.z = original_position.z - current_recoil
	
	# Play effects
	_play_muzzle_flash()
	_play_shell_ejection()
	
	# If we're starting a burst
	if can_burst_fire and not is_in_burst_mode and Input.is_action_just_pressed("burst_fire"):
		is_in_burst_mode = true
		current_burst_count = 1  # Count this shot
	
	# Call the parent fire method to handle the actual firing
	return super.fire()

# Handle burst fire mode
func _handle_burst_fire() -> void:
	if time_since_last_shot >= 1.0 / (fire_rate * burst_fire_rate_multiplier):
		if current_ammo > 0 and not is_reloading:
			fire()
			current_burst_count += 1
		else:
			# End burst if we can't fire
			is_in_burst_mode = false
			current_burst_count = 0
	
	# End burst when complete
	if current_burst_count >= burst_size:
		is_in_burst_mode = false
		current_burst_count = 0

# Play muzzle flash effect
func _play_muzzle_flash() -> void:
	if muzzle_flash_effect and muzzle_point:
		var flash = muzzle_flash_effect.instantiate()
		muzzle_point.add_child(flash)
		
		# Auto-remove after effect is done
		if flash.has_method("queue_free_after_finished"):
			flash.queue_free_after_finished()
		else:
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(flash):
				flash.queue_free()

# Play shell ejection effect
func _play_shell_ejection() -> void:
	if shell_ejection_effect:
		var ejection_point = muzzle_point  # Could be a separate point
		if ejection_point:
			var shell = shell_ejection_effect.instantiate()
			get_tree().root.add_child(shell)
			shell.global_transform = ejection_point.global_transform
			
			# Apply random force/torque to the shell
			if shell.has_method("apply_ejection_force"):
				# Eject to the right with some randomness
				var ejection_dir = ejection_point.global_transform.basis.x
				var random_variation = Vector3(
					randf_range(-0.1, 0.1),
					randf_range(0.1, 0.3),  # Upward
					randf_range(-0.1, 0.1)
				)
				shell.apply_ejection_force(ejection_dir + random_variation, randf_range(2.0, 4.0))

# Toggle burst fire mode
func toggle_burst_mode() -> void:
	if can_burst_fire:
		is_in_burst_mode = !is_in_burst_mode
		current_burst_count = 0
		Logger.debug("Auto cannon burst mode: %s" % ("Enabled" if is_in_burst_mode else "Disabled"), "AutoCannon")
