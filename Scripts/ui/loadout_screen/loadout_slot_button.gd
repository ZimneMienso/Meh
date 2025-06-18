extends Button
class_name LoadoutScreenButton

signal _request_button_update

# This is only to stop UNUSED_SIGNAL error from appearing
func _ready() -> void:
	_request_button_update.emit()
