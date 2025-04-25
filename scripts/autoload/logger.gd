extends Node
# Logger.gd
# Location: res://scripts/autoload/logger.gd
# Autoload name: Logger

enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	NONE
}

var current_level: int = LogLevel.DEBUG
var log_to_file: bool = false
var log_file_path: String = "user://logs/game.log"
var max_log_size: int = 10485760  # 10MB

func _ready() -> void:
	if log_to_file:
		_ensure_log_directory()

# Set the current log level
func set_level(level: int) -> void:
	current_level = level

# Debug level logging
func debug(message: String, context: String = "") -> void:
	if current_level <= LogLevel.DEBUG:
		_log(message, context, "DEBUG")

# Info level logging
func info(message: String, context: String = "") -> void:
	if current_level <= LogLevel.INFO:
		_log(message, context, "INFO")

# Warning level logging
func warning(message: String, context: String = "") -> void:
	if current_level <= LogLevel.WARNING:
		_log(message, context, "WARNING")

# Error level logging
func error(message: String, context: String = "") -> void:
	if current_level <= LogLevel.ERROR:
		_log(message, context, "ERROR")

# Internal logging function
func _log(message: String, context: String, level: String) -> void:
	var timestamp = Time.get_datetime_string_from_system()
	var formatted_msg = "[%s] [%s] %s: %s" % [timestamp, level, context, message]
	
	print(formatted_msg)
	
	if log_to_file:
		_write_to_log_file(formatted_msg)

# Write message to log file
func _write_to_log_file(message: String) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	
	if not file:
		push_error("Failed to open log file: " + log_file_path)
		return
	
	# Check file size and rotate if necessary
	if file.get_length() > max_log_size:
		_rotate_log_file()
		file = FileAccess.open(log_file_path, FileAccess.WRITE)
	else:
		file.seek_end()
	
	file.store_line(message)
	file.close()

# Ensure log directory exists
func _ensure_log_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")

# Rotate log file when it gets too big
func _rotate_log_file() -> void:
	var dir = DirAccess.open("user://logs")
	if dir:
		var old_log_path = log_file_path + ".old"
		if FileAccess.file_exists(old_log_path):
			dir.remove(old_log_path)
		dir.rename(log_file_path, old_log_path)
