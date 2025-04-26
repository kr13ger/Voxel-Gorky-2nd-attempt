# Location: res://scripts/vehicles/player_vehicle.gd
# Fix for vehicle movement issue

extends Vehicle
# Player-controlled vehicle (BTR-82a)

class_name PlayerVehicle

# Physics parameters
@export_group("Vehicle Physics")
@export var engine_force_value: float = 20000.0  # Increased for better movement
@export var brake_force_value: float = 100.0
@export var max_steering_angle: float = 0.5
@export var steering_speed: float = 2.0
@export var mass_override: float = 13600.0

# Current steering state
var current_steering: float = 0.0
var current_engine_force: float = 0.0
var current_brake: float = 0.0

# References to wheels
@export var wheel_paths: Array[NodePath] = []
var wheels: Array[VehicleWheel3D] = []

# Reference to turret and weapon
@export var turret_path: NodePath
var turret: Turret = null
var weapon: Weapon = null

func _ready() -> void:
	super._ready()
	
	# Override mass for more realistic physics
	mass = mass_override
	
	# Debug print to confirm input bindings
	Logger.debug("Input bindings: accelerate=%s, brake=%s, steer_left=%s, steer_right=%s" % 
		[InputMap.has_action("accelerate"), InputMap.has_action("brake"), 
		InputMap.has_action("steer_left"), InputMap.has_action("steer_right")], "PlayerVehicle")
	
	# Get wheel references
	for path in wheel_paths:
		if not path.is_empty():
			var wheel = get_node(path)
			if wheel is VehicleWheel3D:
				wheels.append(wheel)
				Logger.debug("Added wheel: %s, uses_as_traction=%s, use_as_steering=%s" % 
					[wheel.name, wheel.use_as_traction, wheel.use_as_steering], "PlayerVehicle")
	
	# Configure wheels if none are set for traction
	var has_traction_wheel = false
	var has_steering_wheel = false
	
	for wheel in wheels:
		if wheel.use_as_traction:
			has_traction_wheel = true
		if wheel.use_as_steering:
			has_steering_wheel = true
	
	# If no wheels are set for traction or steering, configure the first 4 as both
	if not has_traction_wheel or not has_steering_wheel:
		Logger.warning("No traction or steering wheels configured, setting defaults", "PlayerVehicle")
		for i in range(min(4, wheels.size())):
			wheels[i].use_as_traction = true
			wheels[i].use_as_steering = true
			Logger.debug("Configured wheel %s as traction and steering" % wheels[i].name, "PlayerVehicle")
	
	# Get turret reference - making sure we get the actual Turret component
	if not turret_path.is_empty():
		var node = get_node(turret_path)
		if node is Turret:
			turret = node
			# If we want the weapon, we can get it from the turret
			if turret.attached_weapon is Weapon:
				weapon = turret.attached_weapon
		else:
			# If path points to a weapon slot instead of a turret, try to find the parent turret
			var parent = node.get_parent()
			if parent is Turret:
				turret = parent
				# Find weapon in the slot
				for child in node.get_children():
					if child is Weapon:
						weapon = child
						break
			else:
				Logger.error("turret_path does not point to a Turret component", "PlayerVehicle")
	
	Logger.info("Player vehicle initialized with %d wheels" % wheels.size(), "PlayerVehicle")

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	
	_handle_input(delta)
	
	# Debug vehicle state
	if Input.is_action_just_pressed("accelerate") or Input.is_action_just_pressed("brake"):
		Logger.debug("Input detected: accelerate=%s, brake=%s, current_engine_force=%.2f" % 
			[Input.is_action_pressed("accelerate"), Input.is_action_pressed("brake"), current_engine_force], "PlayerVehicle")

func _handle_input(delta: float) -> void:
	# Get input values
	var throttle_input = Input.get_axis("brake", "accelerate")
	var steering_input = Input.get_axis("steer_right", "steer_left")
	
	if abs(throttle_input) > 0.01 or abs(steering_input) > 0.01:
		Logger.debug("Input values: throttle=%.2f, steering=%.2f" % [throttle_input, steering_input], "PlayerVehicle")
	
	# Smooth steering for more realistic feel
	var target_steering = steering_input * max_steering_angle
	current_steering = lerp(current_steering, target_steering, steering_speed * delta)
	
	# Apply steering to all wheels
	for wheel in wheels:
		if wheel.use_as_steering:
			wheel.steering = current_steering
	
	# Engine force and braking
	if throttle_input > 0:
		# Accelerating
		current_engine_force = engine_force_value * throttle_input
		current_brake = 0.0
	elif throttle_input < 0:
		# Braking/reversing
		if linear_velocity.length() > 0.5 and linear_velocity.dot(transform.basis.z) > 0:
			# Vehicle is moving forward, apply brakes
			current_engine_force = 0.0
			current_brake = brake_force_value
		else:
			# Vehicle is stopped or moving backward, apply reverse
			current_engine_force = engine_force_value * throttle_input * 0.5  # 50% power for reverse
			current_brake = 0.0
	else:
		# No input, gradually slow down
		current_engine_force = 0.0
		current_brake = brake_force_value * 0.3  # Light braking when no input
	
	# Apply engine force to all wheels
	for wheel in wheels:
		if wheel.use_as_traction:
			wheel.engine_force = current_engine_force
			wheel.brake = current_brake
			
	# Direct debug access to VehicleBody3D properties
	engine_force = current_engine_force
	brake = current_brake

# Override the destroy method to handle player-specific destruction behavior
func _on_destroyed() -> void:
	# Disable controls when destroyed
	engine_force = 0.0
	brake = brake_force_value
	
	# Apply visual effects or animations for destruction
	# This would be implemented based on your specific requirements
	
	Logger.info("Player vehicle destroyed, controls disabled", "PlayerVehicle")
