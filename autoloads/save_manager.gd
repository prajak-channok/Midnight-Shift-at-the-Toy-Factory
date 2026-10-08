extends Node
## Persists progress as JSON in user://. Only the unlocked nights are stored.

signal progress_changed

const SAVE_PATH := "user://save.json"
const KEY_UNLOCKED_NIGHTS := "unlocked_nights"
const FIRST_NIGHT := 1
const LAST_NIGHT := 5

var unlocked_nights: int = FIRST_NIGHT


func _ready() -> void:
	load_game()


func is_night_unlocked(night: int) -> bool:
	return night <= unlocked_nights


## Call when the player survives [param night]; unlocks the next one (up to [constant LAST_NIGHT]).
func complete_night(night: int) -> void:
	var next := mini(night + 1, LAST_NIGHT)
	if next <= unlocked_nights:
		return
	unlocked_nights = next
	save_game()
	progress_changed.emit()


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify({KEY_UNLOCKED_NIGHTS: unlocked_nights}, "\t"))


func load_game() -> void:
	unlocked_nights = FIRST_NIGHT
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary and data.get(KEY_UNLOCKED_NIGHTS) is float:
		unlocked_nights = clampi(int(data[KEY_UNLOCKED_NIGHTS]), FIRST_NIGHT, LAST_NIGHT)
