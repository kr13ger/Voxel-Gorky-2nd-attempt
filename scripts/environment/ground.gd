extends StaticBody3D
# Ground.gd
# Location: res://scripts/environment/ground.gd
# Ground system with deformation support

class_name Ground

# Ground properties
@export_group("Terrain Setup")
@export var terrain_mesh: Mesh
@export var collision_shape: Shape3D
@export var generate_collision_from_mesh: bool = true

# Material properties
@export_group("Material Properties")
@export var ground_material: Material
@export var crater_depth: float = 0.5  # How deep craters go
@export var crater_size: float = 2.0  # Base size of craters
@export var max_deformations: int = 100  # Limit deformations for performance

# Internal references
var mesh_instance: MeshInstance3D
var collision_shape_node: CollisionShape3D
var deformation_system: GroundDeformation

# Deformation history for cleanup/undo
var deformation_points: Array = []

func _ready() -> void:
	Logger.info("Ground system initializing", "Ground")
	
	# Setup mesh
	_setup_mesh()
	
	# Setup collision
	_setup_collision()
	
	# Create deformation system
	_setup_deformation_system()
	
	# Connect to signals
	SignalBus.connect("explosion_occurred", _on_explosion_occurred)
	SignalBus.connect("object_hit", _on_object_hit)
	
	Logger.info("Ground system ready", "Ground")

func _setup_mesh() -> void:
	# Check if we already have a MeshInstance3D
	mesh_instance = get_node_or_null("MeshInstance3D")
	
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
	
	# Assign mesh and material
	if terrain_mesh:
		mesh_instance.mesh = terrain_mesh
		Logger.debug("Terrain mesh assigned", "Ground")
	else:
		Logger.warning("No terrain mesh assigned", "Ground")
	
	if ground_material:
		mesh_instance.material_override = ground_material
		Logger.debug("Ground material assigned", "Ground")
	else:
		Logger.warning("No ground material assigned", "Ground")

func _setup_collision() -> void:
	# Check if we already have a CollisionShape3D
	collision_shape_node = get_node_or_null("CollisionShape3D")
	
	if not collision_shape_node:
		collision_shape_node = CollisionShape3D.new()
		collision_shape_node.name = "CollisionShape3D"
		add_child(collision_shape_node)
	
	# Assign collision shape
	if collision_shape:
		collision_shape_node.shape = collision_shape
		Logger.debug("Collision shape assigned", "Ground")
	elif generate_collision_from_mesh and terrain_mesh:
		# Generate collision shape from mesh
		var shape_gen = ConcavePolygonShape3D.new()
		shape_gen.set_faces(terrain_mesh.get_faces())
		collision_shape_node.shape = shape_gen
		Logger.debug("Collision shape generated from mesh", "Ground")
	else:
		Logger.warning("No collision shape assigned", "Ground")

func _setup_deformation_system() -> void:
	# Create and setup deformation system
	deformation_system = GroundDeformation.new()
	deformation_system.setup(mesh_instance, crater_depth, crater_size)
	add_child(deformation_system)
	Logger.debug("Deformation system initialized", "Ground")

# Handle explosions for ground deformation
func _on_explosion_occurred(position: Vector3, radius: float, force: float) -> void:
	var local_pos = global_transform.inverse() * position
	
	# Only deform if explosion is near the ground (within 5 units)
	if abs(local_pos.y) < 5.0:
		# Adjust position to be exactly on the ground surface
		local_pos.y = 0
		
		# Add deformation
		var crater_radius = radius * (0.5 + force / 1000.0)  # Scale based on force
		deformation_system.add_deformation(local_pos, crater_radius)
		
		# Track deformation for potential cleanup
		_add_deformation_point(local_pos, crater_radius)
		
		Logger.debug("Created crater at position: %s, radius: %.2f" % [local_pos, crater_radius], "Ground")

# Handle impacts for smaller deformations
func _on_object_hit(object_id: int, hit_position: Vector3, hit_force: float) -> void:
	# Only consider significant impacts
	if hit_force < 100.0:
		return
		
	var local_pos = global_transform.inverse() * hit_position
	
	# Only deform if hit is near the ground (within 1 unit)
	if abs(local_pos.y) < 1.0:
		# Adjust position to be exactly on the ground surface
		local_pos.y = 0
		
		# Add small deformation
		var small_crater_radius = hit_force / 500.0  # Scale based on impact force
		small_crater_radius = clamp(small_crater_radius, 0.2, 1.0)
		
		deformation_system.add_deformation(local_pos, small_crater_radius)
		
		# Track deformation for potential cleanup
		_add_deformation_point(local_pos, small_crater_radius)
		
		Logger.debug("Created impact mark at position: %s, radius: %.2f" % [local_pos, small_crater_radius], "Ground")

# Track deformation points for cleanup
func _add_deformation_point(position: Vector3, radius: float) -> void:
	deformation_points.append({
		"position": position,
		"radius": radius
	})
	
	# Limit the number of deformations
	if deformation_points.size() > max_deformations:
		# Remove oldest deformation
		var oldest = deformation_points.pop_front()
		# We don't actually restore the mesh here as it would be complex
		# Just limiting the total deformations for performance
	
# Method to repair/reset all deformations
func reset_deformations() -> void:
	deformation_system.reset_deformations()
	deformation_points.clear()
	Logger.debug("Reset all ground deformations", "Ground")
