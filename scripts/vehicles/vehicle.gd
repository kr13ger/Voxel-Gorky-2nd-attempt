extends VehicleBody3D
# Vehicle.gd
# Location: res://scripts/vehicles/vehicle.gd
# Base class for all vehicles

class_name Vehicle

# Vehicle properties
@export var vehicle_id: String = ""
@export var display_name: String = "Vehicle"
@export var description: String = "A vehicle"
@export var max_health: float = 1000.0

# Components
@export var hull_node_path: NodePath
@export var components: Array[Component] = []

# Current state
var current_health: float
var is_destroyed: bool = false
var hull: Component = null

func _ready() -> void:
	current_health = max_health
	if vehicle_id.is_empty():
		vehicle_id = str(get_instance_id())
	
	# Get hull reference if specified
	if not hull_node_path.is_empty():
		hull = get_node(hull_node_path)
	
	# Collect all components
	_collect_components()
	
	Logger.info("Vehicle initialized: %s (ID: %s)" % [display_name, vehicle_id], "Vehicle")

# Collect all components attached to this vehicle
func _collect_components() -> void:
	components.clear()
	
	# Recursively find all Component nodes
	var nodes_to_check = [self]
	while not nodes_to_check.is_empty():
		var current = nodes_to_check.pop_front()
		
		for child in current.get_children():
			if child is Component:
				components.append(child)
			
			if child.get_child_count() > 0:
				nodes_to_check.append(child)
	
	Logger.debug("Found %d components for vehicle %s" % [components.size(), vehicle_id], "Vehicle")

# Apply damage to the vehicle
func take_damage(damage_amount: float, hit_position: Vector3 = Vector3.ZERO) -> void:
	if is_destroyed:
		return
		
	current_health -= damage_amount
	
	# Emit signal that this vehicle was damaged
	SignalBus.emit_signal("vehicle_damaged", get_instance_id(), damage_amount, hit_position)
	
	Logger.debug("Vehicle damaged: %s (ID: %s), Health: %.1f/%.1f" % 
		[display_name, vehicle_id, current_health, max_health], "Vehicle")
	
	if current_health <= 0:
		destroy()

# Destroy the vehicle
func destroy() -> void:
	if is_destroyed:
		return
		
	is_destroyed = true
	current_health = 0
	
	# Emit signal that this vehicle was destroyed
	SignalBus.emit_signal("vehicle_destroyed", get_instance_id())
	
	Logger.info("Vehicle destroyed: %s (ID: %s)" % [display_name, vehicle_id], "Vehicle")
	
	# Handle destruction effects or behavior
	_on_destroyed()

# Virtual method to be overridden by child classes
func _on_destroyed() -> void:
	pass

# Repair the vehicle
func repair(repair_amount: float) -> void:
	if is_destroyed:
		return
		
	current_health = min(current_health + repair_amount, max_health)
	Logger.debug("Vehicle repaired: %s (ID: %s), Health: %.1f/%.1f" % 
		[display_name, vehicle_id, current_health, max_health], "Vehicle")

# Fully repair the vehicle
func repair_full() -> void:
	if is_destroyed:
		is_destroyed = false
		
	current_health = max_health
	Logger.debug("Vehicle fully repaired: %s (ID: %s)" % [display_name, vehicle_id], "Vehicle")

# Get the health percentage (0-100)
func get_health_percentage() -> float:
	return (current_health / max_health) * 100.0

# Get a component by ID
func get_component_by_id(component_id: String) -> Component:
	for component in components:
		if component.component_id == component_id:
			return component
	return null
