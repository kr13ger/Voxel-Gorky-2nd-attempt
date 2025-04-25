extends Node3D
# Component.gd
# Location: res://scripts/components/component.gd
# Base class for all vehicle components

class_name Component

# Component properties
@export var component_id: String = ""
@export var display_name: String = "Component"
@export var description: String = "A vehicle component"
@export var max_health: float = 100.0
@export var value: int = 0
@export var mass: float = 10.0

# Current state
var current_health: float
var is_destroyed: bool = false

# Optional parent component reference
var parent_component: Component = null

func _ready() -> void:
	current_health = max_health
	if component_id.is_empty():
		component_id = str(get_instance_id())
	
	Logger.debug("Component initialized: %s (ID: %s)" % [display_name, component_id], "Component")

# Apply damage to the component
func take_damage(damage_amount: float) -> void:
	if is_destroyed:
		return
		
	current_health -= damage_amount
	
	# Emit signal that this component was damaged
	SignalBus.emit_signal("vehicle_component_damaged", get_parent_vehicle_id(), component_id, damage_amount)
	
	Logger.debug("Component damaged: %s (ID: %s), Health: %.1f/%.1f" % 
		[display_name, component_id, current_health, max_health], "Component")
	
	if current_health <= 0:
		destroy()

# Destroy the component
func destroy() -> void:
	if is_destroyed:
		return
		
	is_destroyed = true
	current_health = 0
	
	# Emit signal that this component was destroyed
	SignalBus.emit_signal("vehicle_component_destroyed", get_parent_vehicle_id(), component_id)
	
	Logger.info("Component destroyed: %s (ID: %s)" % [display_name, component_id], "Component")
	
	# Handle destruction effects or behavior
	_on_destroyed()

# Virtual method to be overridden by child classes
func _on_destroyed() -> void:
	pass

# Repair the component
func repair(repair_amount: float) -> void:
	if is_destroyed:
		return
		
	current_health = min(current_health + repair_amount, max_health)
	Logger.debug("Component repaired: %s (ID: %s), Health: %.1f/%.1f" % 
		[display_name, component_id, current_health, max_health], "Component")

# Fully repair the component
func repair_full() -> void:
	if is_destroyed:
		is_destroyed = false
		
	current_health = max_health
	Logger.debug("Component fully repaired: %s (ID: %s)" % [display_name, component_id], "Component")

# Get the health percentage (0-100)
func get_health_percentage() -> float:
	return (current_health / max_health) * 100.0

# Get the ID of the parent vehicle (traverse up the tree to find it)
func get_parent_vehicle_id() -> int:
	var parent = get_parent()
	while parent and not parent is Vehicle:
		parent = parent.get_parent()
	
	if parent and parent is Vehicle:
		return parent.get_instance_id()
	return -1
