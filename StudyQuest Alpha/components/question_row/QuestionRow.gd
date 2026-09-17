extends Button

signal question_selected(question_id: int)

@onready var info: VBoxContainer = $RowMargin/RowLayout/QuestionInfo
@onready var question_label: Label = info.get_node("lblQuestionText")
@onready var subject_label: Label = info.get_node("Tags/lblSubject")
@onready var difficulty_label: Label = info.get_node("Tags/lblDifficulty")
@onready var type_label: Label = info.get_node("Tags/lblQuestionType")
@onready var visibility_label: Label = info.get_node("Tags/lblVisibility")

var question_id: int = -1


func _ready() -> void:
	text = ""
	toggle_mode = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Decorative children must not intercept the row's clicks.
	ignore_child_mouse(self)

	pressed.connect(_on_pressed)

	# A Button does not automatically fit itself to child content.
	resized.connect(update_height)
	$RowMargin.minimum_size_changed.connect(update_height)
	update_height.call_deferred()


func ignore_child_mouse(parent: Node) -> void:
	for child in parent.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_child_mouse(child)


func update_height() -> void:
	var required_height: float = maxf(
		100.0,
		$RowMargin.get_combined_minimum_size().y
	)
	if not is_equal_approx(custom_minimum_size.y, required_height):
		custom_minimum_size.y = required_height


# Call after adding this row to the scene tree.
func set_question(question: Dictionary) -> void:
	question_id = int(question["id"])
	question_label.text = str(question["question"])
	subject_label.text = str(question["subject"])
	difficulty_label.text = str(question["difficulty"])
	type_label.text = str(question["type"])
	visibility_label.text = str(question["visibility"])
	update_height.call_deferred()


func _on_pressed() -> void:
	question_selected.emit(question_id)
