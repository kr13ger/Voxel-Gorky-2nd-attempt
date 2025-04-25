extends Node
# DependencyContainer.gd
# Location: res://scripts/autoload/dependency_container.gd
# Autoload name: DependencyContainer

# Dictionary to store our dependencies
var _container: Dictionary = {}

func _ready() -> void:
	Logger.info("DependencyContainer initialized", "DependencyContainer")

# Register a dependency with the container
func register(key: String, instance) -> void:
	if _container.has(key):
		Logger.warning("Dependency with key '%s' already registered, overwriting" % key, "DependencyContainer")
	
	_container[key] = instance
	Logger.debug("Registered dependency: %s" % key, "DependencyContainer")

# Retrieve a dependency from the container
func resolve(key: String):
	if not _container.has(key):
		Logger.error("Dependency with key '%s' not found" % key, "DependencyContainer")
		return null
	
	return _container[key]

# Check if a dependency exists
func has(key: String) -> bool:
	return _container.has(key)

# Remove a dependency from the container
func remove(key: String) -> void:
	if _container.has(key):
		_container.erase(key)
		Logger.debug("Removed dependency: %s" % key, "DependencyContainer")
	else:
		Logger.warning("Tried to remove non-existent dependency: %s" % key, "DependencyContainer")

# Clear all dependencies
func clear() -> void:
	_container.clear()
	Logger.debug("Cleared all dependencies", "DependencyContainer")

# Get a list of all registered dependencies
func get_all_keys() -> Array:
	return _container.keys()
