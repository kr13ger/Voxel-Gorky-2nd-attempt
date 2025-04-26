extends Node
# GroundDeformation.gd
# Location: res://scripts/environment/ground_deformation.gd
# Handles ground mesh deformation for craters and tracks

class_name GroundDeformation

# Configuration
var crater_depth: float = 0.5
var crater_size: float = 2.0

# References
var target_mesh_instance: MeshInstance3D
var original_mesh_data: Array = []
var mesh_tool: MeshDataTool

# State
var is_initialized: bool = false

func _ready() -> void:
	Logger.debug("Ground deformation system ready", "GroundDeformation")

# Initialize the system with a target mesh
func setup(mesh_instance: MeshInstance3D, depth: float = 0.5, size: float = 2.0) -> void:
	target_mesh_instance = mesh_instance
	crater_depth = depth
	crater_size = size
	
	# Make sure we have a valid mesh to work with
	if not target_mesh_instance or not target_mesh_instance.mesh:
		Logger.error("No valid mesh provided for deformation", "GroundDeformation")
		return
	
	# Create a unique instance of the mesh to modify
	var original_mesh = target_mesh_instance.mesh
	var mesh = original_mesh.duplicate(true)
	target_mesh_instance.mesh = mesh
	
	# Initialize MeshDataTool
	mesh_tool = MeshDataTool.new()
	var surface_count = mesh.get_surface_count()
	
	if surface_count == 0:
		Logger.error("Mesh has no surfaces", "GroundDeformation")
		return
	
	# Store original vertex data for all surfaces
	for surface_idx in range(surface_count):
		# Store original surface data
		var result = mesh_tool.create_from_surface(mesh, surface_idx)
		if result != OK:
			Logger.error("Failed to create MeshDataTool from surface %d" % surface_idx, "GroundDeformation")
			continue
		
		var surface_data = {
			"vertices": [],
			"surface_idx": surface_idx
		}
		
		# Store original vertex positions
		for i in range(mesh_tool.get_vertex_count()):
			surface_data.vertices.append(mesh_tool.get_vertex(i))
		
		original_mesh_data.append(surface_data)
		
		# Clear for next surface
		mesh_tool.clear()
	
	is_initialized = true
	Logger.debug("Ground deformation initialized with %d surfaces" % surface_count, "GroundDeformation")

# Add a deformation at the specified position
func add_deformation(position: Vector3, radius: float = 1.0) -> void:
	if not is_initialized or not target_mesh_instance:
		Logger.warning("Deformation system not initialized", "GroundDeformation")
		return
	
	# Get the mesh to modify
	var mesh = target_mesh_instance.mesh
	if not mesh:
		return
	
	# Process each surface
	for surface_idx in range(mesh.get_surface_count()):
		# Get mesh data
		var result = mesh_tool.create_from_surface(mesh, surface_idx)
		if result != OK:
			continue
		
		# Deform vertices
		_deform_vertices(position, radius)
		
		# Commit changes
		mesh_tool.commit_to_surface(mesh)
		
		# Clear for next surface
		mesh_tool.clear()
	
	Logger.debug("Added deformation at %s with radius %.2f" % [position, radius], "GroundDeformation")

# Deform vertices around a position
func _deform_vertices(position: Vector3, radius: float) -> void:
	# Squared radius for faster distance checks
	var radius_squared = radius * radius
	var depth = crater_depth
	
	# Process all vertices
	for i in range(mesh_tool.get_vertex_count()):
		var vertex = mesh_tool.get_vertex(i)
		
		# Calculate distance from deformation center
		var dx = vertex.x - position.x
		var dz = vertex.z - position.z
		var distance_squared = dx * dx + dz * dz
		
		# Skip vertices outside radius
		if distance_squared > radius_squared:
			continue
		
		# Calculate deformation based on distance
		var distance = sqrt(distance_squared)
		var deform_factor = 1.0 - (distance / radius)
		deform_factor = pow(deform_factor, 2)  # Squared for smoother crater shape
		
		# Apply deformation (only to Y-axis)
		vertex.y -= depth * deform_factor
		
		# Update vertex
		mesh_tool.set_vertex(i, vertex)
	
	# Recalculate normals for proper lighting
	mesh_tool.recalculate_normals()

# Reset mesh to original state
func reset_deformations() -> void:
	if not is_initialized or not target_mesh_instance or original_mesh_data.size() == 0:
		return
	
	var mesh = target_mesh_instance.mesh
	if not mesh:
		return
	
	# Process each surface
	for surface_data in original_mesh_data:
		var surface_idx = surface_data.surface_idx
		
		# Get mesh data
		var result = mesh_tool.create_from_surface(mesh, surface_idx)
		if result != OK:
			continue
		
		# Restore original vertices
		for i in range(min(mesh_tool.get_vertex_count(), surface_data.vertices.size())):
			mesh_tool.set_vertex(i, surface_data.vertices[i])
		
		# Commit changes
		mesh_tool.commit_to_surface(mesh)
		
		# Clear for next surface
		mesh_tool.clear()
	
	Logger.debug("Reset all deformations to original state", "GroundDeformation")
