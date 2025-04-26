# Location: res://scripts/debug/input_debugger.gd
# Script to verify input system is working

extends Node

func _ready() -> void:
	Logger.info("Input debugger initialized", "InputDebugger")

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_W):
		Logger.debug("W key pressed (mapped to accelerate: %s)" % InputMap.has_action("accelerate"), "InputDebugger")
	
	if Input.is_key_pressed(KEY_S):
		Logger.debug("S key pressed (mapped to brake: %s)" % InputMap.has_action("brake"), "InputDebugger")
	
	if Input.is_key_pressed(KEY_A):
		Logger.debug("A key pressed (mapped to steer_left: %s)" % InputMap.has_action("steer_left"), "InputDebugger")
	
	if Input.is_key_pressed(KEY_D):
		Logger.debug("D key pressed (mapped to steer_right: %s)" % InputMap.has_action("steer_right"), "InputDebugger")
