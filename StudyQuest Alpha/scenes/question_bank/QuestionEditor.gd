extends Control

const BANK_PATH: String = "res://scenes/question_bank/QuestionBank.tscn"

@onready var layout: VBoxContainer = $ScreenMargin/MainLayout
@onready var editor: VBoxContainer = layout.get_node("EditorScroll/EditorLayout")
@onready var details: VBoxContainer = editor.get_node("DetailsPanel/DetailsMargin/DetailsLayout")
@onready var choices_layout: VBoxContainer = editor.get_node("MultipleChoicePanel/ChoicesMargin/ChoicesLayout")
@onready var title: Label = layout.get_node("Header/TitleSection/lblTitle")
@onready var error_label: Label = layout.get_node("lblError")
@onready var save_button: Button = layout.get_node("BottomActions/btnSave")
@onready var subject: OptionButton = details.get_node("SubjectSection/optSubject")
@onready var difficulty: OptionButton = details.get_node("DifficultySection/optDifficulty")
@onready var question_type: OptionButton = details.get_node("TypeSection/optQuestionType")
@onready var visibility: OptionButton = details.get_node("VisibilitySection/optVisibility")
@onready var team: OptionButton = details.get_node("TeamSection/optTeam")
@onready var question_text: TextEdit = editor.get_node("QuestionPanel/QuestionMargin/QuestionLayout/txtQuestion")
@onready var correct_answer: LineEdit = editor.get_node("IdentificationPanel/AnswerMargin/AnswerLayout/txtCorrectAnswer")
@onready var discard_dialog: ConfirmationDialog = $DiscardConfirmation

var choice_inputs: Array[LineEdit] = []
var correct_buttons: Array[CheckBox] = []
var original_state: Dictionary = {}
var editing_id: int = -1
var navigating: bool = false


func _ready() -> void:
	fill_options(subject, QuestionStore.SUBJECTS)
	fill_options(difficulty, QuestionStore.DIFFICULTIES)
	fill_options(question_type, QuestionStore.TYPES)
	fill_options(visibility, QuestionStore.VISIBILITIES)

	team.clear()
	team.add_item("Select a team", 0)
	for entry in QuestionStore.teams:
		team.add_item(str(entry["name"]), int(entry["id"]))

	var group := ButtonGroup.new()
	group.allow_unpress = false

	for letter in ["A", "B", "C", "D"]:
		var row: HBoxContainer = choices_layout.get_node(
			"Choice%sRow" % letter
		)
		var input: LineEdit = row.get_node("txtChoice%s" % letter)
		var checkbox: CheckBox = row.get_node("radioCorrect%s" % letter)

		checkbox.button_group = group
		checkbox.set_pressed_no_signal(false)
		choice_inputs.append(input)
		correct_buttons.append(checkbox)
		input.clear()

	question_text.text = ""
	correct_answer.clear()
	error_label.text = ""

	question_type.item_selected.connect(update_sections)
	visibility.item_selected.connect(update_sections)
	save_button.pressed.connect(save_question)

	layout.get_node("Header/btnBack").pressed.connect(request_back)
	layout.get_node("BottomActions/btnCancel").pressed.connect(request_back)

	discard_dialog.dialog_text = "Discard your unsaved changes?"
	discard_dialog.confirmed.connect(return_to_bank)

	editing_id = QuestionStore.editing_id
	title.text = "Add Question" if editing_id == -1 else "Edit Question"
	save_button.text = "Save Question" if editing_id == -1 else "Save Changes"

	if editing_id != -1:
		if QuestionStore.can_edit(editing_id):
			load_question(QuestionStore.get_question(editing_id))
		else:
			error_label.text = "This question is unavailable or cannot be edited."
			save_button.disabled = true

	update_sections()
	original_state = form_state()


func fill_options(control: OptionButton, items: Array) -> void:
	control.clear()
	for item in items:
		control.add_item(str(item))
	control.select(0)


func select_text(control: OptionButton, value: String) -> void:
	for i in range(control.item_count):
		if control.get_item_text(i) == value:
			control.select(i)
			return


func selected_text(control: OptionButton) -> String:
	if control.selected < 0:
		return ""
	return control.get_item_text(control.selected)


func update_sections(_index: int = 0) -> void:
	var multiple_choice: bool = question_type.selected == 0
	editor.get_node("MultipleChoicePanel").visible = multiple_choice
	editor.get_node("IdentificationPanel").visible = not multiple_choice
	details.get_node("TeamSection").visible = visibility.selected == 2


func load_question(question: Dictionary) -> void:
	select_text(subject, str(question["subject"]))
	select_text(difficulty, str(question["difficulty"]))
	select_text(question_type, str(question["type"]))
	select_text(visibility, str(question["visibility"]))

	var team_index: int = team.get_item_index(int(question["team_id"]))
	team.select(team_index if team_index >= 0 else 0)

	question_text.text = str(question["question"])

	if question["type"] == "Multiple Choice":
		for i in range(4):
			choice_inputs[i].text = str(question["choices"][i])
			correct_buttons[i].set_pressed_no_signal(
				i == int(question["correct_index"])
			)
	else:
		correct_answer.text = str(question["answer"])


func selected_correct_index() -> int:
	for i in range(correct_buttons.size()):
		if correct_buttons[i].button_pressed:
			return i
	return -1


# Includes hidden fields so changing type does not hide unsaved edits.
func form_state() -> Dictionary:
	var choices: Array[String] = []
	for input in choice_inputs:
		choices.append(input.text)

	return {
		"subject": subject.selected,
		"difficulty": difficulty.selected,
		"type": question_type.selected,
		"visibility": visibility.selected,
		"team": team.get_selected_id(),
		"question": question_text.text,
		"choices": choices,
		"correct": selected_correct_index(),
		"answer": correct_answer.text
	}


func save_question() -> void:
	if navigating or save_button.disabled:
		return

	error_label.text = ""

	if question_text.text.strip_edges().is_empty():
		error_label.text = "Please enter a question."
		return

	if visibility.selected == 2 and team.get_selected_id() <= 0:
		error_label.text = "Please select a team."
		return

	var choices: Array[String] = []
	var answer: String = correct_answer.text.strip_edges()
	var correct_index: int = -1

	if question_type.selected == 0:
		for input in choice_inputs:
			var choice: String = input.text.strip_edges()
			if choice.is_empty():
				error_label.text = "Enter all four answer choices."
				return
			choices.append(choice)

		for i in range(choices.size()):
			for j in range(i):
				if choices[i].to_lower() == choices[j].to_lower():
					error_label.text = "Answer choices must be different."
					return

		correct_index = selected_correct_index()
		if correct_index == -1:
			error_label.text = "Select the correct answer."
			return

		answer = choices[correct_index]
	elif answer.is_empty():
		error_label.text = "Enter the correct answer."
		return

	var data: Dictionary = {
		"subject": selected_text(subject),
		"difficulty": selected_text(difficulty),
		"type": selected_text(question_type),
		"visibility": selected_text(visibility),
		"team_id": team.get_selected_id() if visibility.selected == 2 else -1,
		"question": question_text.text.strip_edges(),
		"choices": choices,
		"correct_index": correct_index,
		"answer": answer
	}

	var saved_id: int = QuestionStore.save_question(data, editing_id)
	if saved_id == -1:
		error_label.text = "Could not save this question."
		return

	# Prevent duplicate creation if returning to the bank fails.
	editing_id = saved_id
	QuestionStore.editing_id = saved_id
	original_state = form_state()
	return_to_bank()


func request_back() -> void:
	if navigating:
		return

	if form_state() != original_state:
		discard_dialog.popup_centered()
	else:
		return_to_bank()


func return_to_bank() -> void:
	if navigating:
		return

	navigating = true
	var error := get_tree().change_scene_to_file(BANK_PATH)

	if error != OK:
		navigating = false
		error_label.text = "Could not open Question Bank. Check BANK_PATH."
	else:
		QuestionStore.editing_id = -1
