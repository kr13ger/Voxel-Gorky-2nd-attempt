# Location: res://scripts/debug/vehicle_physics_debugger.gd
# Helper to debug vehicle physics issues

extends Node

class_name VehiclePhysicsDebugger

var target_vehicle: Vehicle = null
var is_active: bool = true
var update_interval: float = 1.0
var time_since_last_update: float = 0.0

func _ready() -> void:
	Logger.info("Vehicle Physics Debugger initialized", "PhysicsDebugger")

func setup(vehicle: Vehicle) -> void:
	target_vehicle = vehicle
	Logger.info("Vehicle Physics Debugger attached to %s" % vehicle.name, "PhysicsDebugger")

func _process(delta: float) -> void:
	if not is_active or not target_vehicle:
		return
		
	time_since_last_update += delta
	if time_since_last_update >= update_interval:
		_log_vehicle_state()
		time_since_last_update = 0.0

func _log_vehicle_state() -> void:
	if not target_vehicle:
		return
		
	Logger.debug("Vehicle Position: %s" % target_vehicle.global_position, "PhysicsDebugger")
	Logger.debug("Vehicle Linear Velocity: %s (Speed: %.2f m/s)" % 
		[target_vehicle.linear_velocity, target_vehicle.linear_velocity.length()], "PhysicsDebugger")
	
	var on_ground = false
	
	# Check if any wheels are in contact with the ground
	if target_vehicle is PlayerVehicle:
		for wheel_path in target_vehicle.wheel_paths:
			if not wheel_path.is_empty():
				var wheel = target_vehicle.get_node(wheel_path)
				if wheel is VehicleWheel3D and wheel.is_in_contact():
					on_ground = true
					break
	
	Logger.debug("Vehicle On Ground: %s" % on_ground, "PhysicsDebugger")
	Logger.debug("Vehicle Engine Force: %.2f" % target_vehicle.engine_force, "PhysicsDebugger") 
	Logger.debug("Vehicle Input State: Brake: %.2f, Steering: %.2f" % 
		[target_vehicle.brake, target_vehicle.steering], "PhysicsDebugger")
