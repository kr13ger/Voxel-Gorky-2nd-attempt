extends Component
# Wheel.gd
# Location: res://scripts/components/wheel.gd
# Vehicle wheel component

class_name Wheel

# Wheel properties
@export var wheel_radius: float = 0.4  # meters
@export var wheel_width: float = 0.3   # meters
@export var is_steering_wheel: bool = false
@export var is_drive_wheel: bool = true

# Physics properties - these will be applied to the VehicleWheel3D node
@export_group("Physics Properties")
@export var wheel_friction: float = 1.0
@export var suspension_stiffness: float = 50.0
@export var suspension_travel: float = 0.2  # meters
@export var suspension_max_force: float = 6000.0
@export var damping_compression: float = 0.3
@export var damping_relaxation: float = 0.5
# Removed roll_influence as it's not a valid property in Godot 4.4

# Visual properties
@export_group("Visual Properties")
@export var wheel_mesh: MeshInstance3D = null
@export var mud_particle_effect: PackedScene = null
@export var damage_mesh: MeshInstance3D = null

# References
var vehicle_wheel_node: VehicleWheel3D = null
var accumulated_rotation: float = 0.0
var last_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	
	# Initialize wheel node reference and physics properties
	vehicle_wheel_node = _find_vehicle_wheel()
	
	if vehicle_wheel_node:
		# Apply physics properties to the VehicleWheel3D node
		_apply_physics_properties()
		Logger.debug("Wheel initialized and linked to VehicleWheel3D", "Wheel")
		
		# Store initial position for movement calculation
		last_position = global_position
	else:
		Logger.warning("Wheel component not linked to any VehicleWheel3D node", "Wheel")

# Find the VehicleWheel3D node in the parent hierarchy
func _find_vehicle_wheel() -> VehicleWheel3D:
	# First check if we're directly attached to a VehicleWheel3D
	var parent = get_parent()
	if parent is VehicleWheel3D:
		return parent
	
	# Then check if there's a VehicleWheel3D among our children
	for child in get_children():
		if child is VehicleWheel3D:
			return child
	
	# Finally, check if there's a VehicleWheel3D node with the same name in our parent's children
	if parent:
		for sibling in parent.get_children():
			if sibling is VehicleWheel3D and sibling.name.contains(name):
				return sibling
	
	return null

# Apply physics properties to the VehicleWheel3D node
func _apply_physics_properties() -> void:
	if not vehicle_wheel_node:
		return
	
	vehicle_wheel_node.wheel_radius = wheel_radius
	vehicle_wheel_node.wheel_rest_length = suspension_travel / 2.0
	vehicle_wheel_node.wheel_friction_slip = wheel_friction * 5.0  # Increased for better traction
	vehicle_wheel_node.suspension_stiffness = suspension_stiffness * 2.0  # Increased for better ground contact
	vehicle_wheel_node.suspension_max_force = suspension_max_force * 2.0  # Increased for better weight handling
	vehicle_wheel_node.suspension_travel = suspension_travel
	vehicle_wheel_node.damping_compression = damping_compression * 2.0  # Increased for stability
	vehicle_wheel_node.damping_relaxation = damping_relaxation * 2.0  # Increased for stability
	vehicle_wheel_node.use_as_steering = is_steering_wheel
	vehicle_wheel_node.use_as_traction = is_drive_wheel
	
	#Logger.debug("Applied physics properties to wheel: radius=%.2f, friction=%.2f, stiffness=%.2f", 
		#[wheel_radius, wheel_friction * 5.0, suspension_stiffness * 2.0], "Wheel")

func _process(delta: float) -> void:
	if is_destroyed:
		return
	
	# Handle wheel rotation visual effect
	if wheel_mesh and vehicle_wheel_node:
		# Calculate proper wheel rotation based on RPM or manual calculation
		var rotation_angle = 0.0
		
		# Try using the VehicleWheel3D RPM first
		var rpm = vehicle_wheel_node.get_rpm()
		
		if abs(rpm) > 0.01:
			# Convert RPM to radians per second and then to rotation this frame
			rotation_angle = rpm * (PI / 30.0) * delta
			Logger.debug("Wheel RPM: %.2f, Rotation: %.5f" % [rpm, rotation_angle], "Wheel") if abs(rpm) > 10.0 else null
		else:
			# Fallback: calculate rotation from movement (useful if RPM isn't updating)
			var current_pos = global_position
			var movement = current_pos - last_position
			
			# Project movement onto wheel's forward vector
			var forward = global_transform.basis.z.normalized()
			var movement_along_forward = forward.dot(movement)
			
			# Calculate rotation based on distance traveled
			rotation_angle = (movement_along_forward / (2.0 * PI * wheel_radius)) * (2.0 * PI)
			
			last_position = current_pos
		
		# Apply rotation to the wheel mesh
		if abs(rotation_angle) > 0.0001:
			wheel_mesh.rotate_x(rotation_angle)
			accumulated_rotation += rotation_angle
		
		# Handle steering visualization (already working)
		if is_steering_wheel and vehicle_wheel_node:
			wheel_mesh.rotation.y = vehicle_wheel_node.steering
		
		# Handle dirt/mud effects when wheel is slipping
		if mud_particle_effect:
			var skid_info = vehicle_wheel_node.get_skid_info()
			if skid_info < 0.9 and vehicle_wheel_node.is_in_contact():
				_emit_mud_particles(1.0 - skid_info)

# Emit mud/dirt particles when wheel is slipping
func _emit_mud_particles(intensity: float) -> void:
	if not mud_particle_effect:
		return
	
	# Only emit particles if we're in contact with the ground
	if vehicle_wheel_node and vehicle_wheel_node.is_in_contact():
		var contact_pos = vehicle_wheel_node.get_contact_position()
		var contact_normal = vehicle_wheel_node.get_contact_normal()
		
		var particles = mud_particle_effect.instantiate()
		get_tree().root.add_child(particles)
		particles.global_position = contact_pos
		
		# Align particles with the ground
		if particles.has_method("set_direction"):
			particles.set_direction(contact_normal)
		
		# Set intensity if the particles support it
		if particles.has_method("set_intensity"):
			particles.set_intensity(intensity)
		
		# Make sure particles clean themselves up
		if particles.has_method("queue_free_after_finished"):
			particles.queue_free_after_finished()
		else:
			await get_tree().create_timer(2.0).timeout
			if is_instance_valid(particles):
				particles.queue_free()

# Handle wheel destruction
func _on_destroyed() -> void:
	# Show damaged wheel mesh if available
	if damage_mesh:
		if wheel_mesh:
			wheel_mesh.visible = false
		damage_mesh.visible = true
	
	# Reduce friction and suspension properties
	if vehicle_wheel_node:
		vehicle_wheel_node.wheel_friction_slip *= 0.5
		vehicle_wheel_node.suspension_stiffness *= 0.7
		vehicle_wheel_node.suspension_max_force *= 0.5
