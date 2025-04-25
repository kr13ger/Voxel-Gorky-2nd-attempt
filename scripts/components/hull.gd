extends Component
# Hull.gd
# Location: res://scripts/components/hull.gd
# Vehicle hull component

class_name Hull

# Attachment points
@export_group("Attachment Points")
@export var wheel_slots: Array[Node3D] = []
@export var turret_slot: Node3D = null

# Armor properties
@export_group("Armor Properties")
@export var armor_thickness_front: float = 10.0  # mm
@export var armor_thickness_sides: float = 8.0   # mm
@export var armor_thickness_rear: float = 7.0    # mm
@export var armor_thickness_top: float = 6.0     # mm
@export var armor_thickness_bottom: float = 6.0  # mm

# Attached components
var attached_wheels: Array[Component] = []
var attached_turret: Component = null

func _ready() -> void:
	super._ready()
	
	# Validate slots
	_validate_slots()
	
	Logger.info("Hull initialized: %s (ID: %s)" % [display_name, component_id], "Hull")
	Logger.debug("Hull armor: F:%.1fmm S:%.1fmm R:%.1fmm T:%.1fmm B:%.1fmm" % 
		[armor_thickness_front, armor_thickness_sides, armor_thickness_rear, 
		armor_thickness_top, armor_thickness_bottom], "Hull")

# Validate that all slots are properly set up
func _validate_slots() -> void:
	var wheel_count = wheel_slots.size()
	Logger.debug("Hull has %d wheel slots" % wheel_count, "Hull")
	
	if turret_slot:
		Logger.debug("Hull has turret slot", "Hull")
	else:
		Logger.warning("Hull missing turret slot", "Hull")

# Attach a wheel to a specific slot
func attach_wheel(wheel: Component, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= wheel_slots.size():
		Logger.error("Invalid wheel slot index: %d" % slot_index, "Hull")
		return false
	
	var slot = wheel_slots[slot_index]
	
	# Parent the wheel to the slot
	wheel.get_parent().remove_child(wheel)
	slot.add_child(wheel)
	wheel.transform = Transform3D.IDENTITY
	
	# Store reference
	while attached_wheels.size() <= slot_index:
		attached_wheels.append(null)
	attached_wheels[slot_index] = wheel
	
	Logger.debug("Attached wheel to slot %d: %s" % [slot_index, wheel.display_name], "Hull")
	return true

# Attach a turret to the hull
func attach_turret(turret: Component) -> bool:
	if not turret_slot:
		Logger.error("No turret slot available", "Hull")
		return false
	
	# Parent the turret to the slot
	if turret.get_parent():
		turret.get_parent().remove_child(turret)
	turret_slot.add_child(turret)
	turret.transform = Transform3D.IDENTITY
	
	# Store reference
	attached_turret = turret
	
	Logger.debug("Attached turret: %s" % turret.display_name, "Hull")
	return true

# Get the armor thickness based on hit direction
func get_armor_thickness(hit_normal: Vector3) -> float:
	# Convert hit normal to local space
	var local_normal = global_transform.basis.inverse() * hit_normal
	
	# Determine which face was hit based on the strongest component
	var strongest_component = 0
	var strongest_value = abs(local_normal.x)
	
	if abs(local_normal.y) > strongest_value:
		strongest_component = 1
		strongest_value = abs(local_normal.y)
	
	if abs(local_normal.z) > strongest_value:
		strongest_component = 2
	
	# Determine which side was hit
	match strongest_component:
		0:  # X-axis (sides)
			return armor_thickness_sides
		1:  # Y-axis (top/bottom)
			return local_normal.y > 0 ? armor_thickness_top : armor_thickness_bottom
		2:  # Z-axis (front/rear)
			return local_normal.z < 0 ? armor_thickness_front : armor_thickness_rear
	
	# Fallback
	return armor_thickness_sides

# Handle hull destruction
func _on_destroyed() -> void:
	# When hull is destroyed, the entire vehicle is disabled
	var parent_vehicle = get_parent()
	if parent_vehicle is Vehicle and not parent_vehicle.is_destroyed:
		parent_vehicle.destroy()
