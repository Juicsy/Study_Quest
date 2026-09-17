extends Control

@onready var lbl_title: Label = $ScreenMargin/MainLayout/Header/TitleSection/lblTitle
@onready var lbl_subject: Label = $ScreenMargin/MainLayout/Header/TitleSection/lblSubject
@onready var lbl_score: Label = $ScreenMargin/MainLayout/Header/lblScore
@onready var btn_exit: Button = $ScreenMargin/MainLayout/Header/btnExit
@onready var lbl_progess: Label = $ScreenMargin/MainLayout/ProgressSection/ProgressHeader/lblProgess
@onready var lbl_timer: Label = $ScreenMargin/MainLayout/ProgressSection/ProgressHeader/lblTimer
@onready var question_progress: ProgressBar = $ScreenMargin/MainLayout/ProgressSection/QuestionProgress
@onready var time_remaining: ProgressBar = $ScreenMargin/MainLayout/ProgressSection/TimeRemaining
@onready var lbl_question_type: Label = $ScreenMargin/MainLayout/QuestionPanel/QuestionMargin/QuestionLayout/lblQuestionType
@onready var lbl_question_text: Label = $ScreenMargin/MainLayout/QuestionPanel/QuestionMargin/QuestionLayout/QuestionScroll/lblQuestionText
@onready var btn_option_a: Button = $ScreenMargin/MainLayout/AnswerSection/MultipleChoiceSection/btnOptionA
@onready var btn_option_b: Button = $ScreenMargin/MainLayout/AnswerSection/MultipleChoiceSection/btnOptionB
@onready var btn_option_c: Button = $ScreenMargin/MainLayout/AnswerSection/MultipleChoiceSection/btnOptionC
@onready var btn_option_d: Button = $ScreenMargin/MainLayout/AnswerSection/MultipleChoiceSection/btnOptionD
@onready var lbl_answer_prompt: Label = $ScreenMargin/MainLayout/AnswerSection/IdentificationSection/lblAnswerPrompt
@onready var txt_answer: LineEdit = $ScreenMargin/MainLayout/AnswerSection/IdentificationSection/txtAnswer
@onready var lbl_feedback: Label = $ScreenMargin/MainLayout/lblFeedback
@onready var bottom_actions: HBoxContainer = $ScreenMargin/MainLayout/BottomActions
@onready var btn_submit: Button = $ScreenMargin/MainLayout/BottomActions/btnSubmit
@onready var btn_next: Button = $ScreenMargin/MainLayout/BottomActions/btnNext
@onready var multiple_choice_section: GridContainer = $ScreenMargin/MainLayout/AnswerSection/MultipleChoiceSection
@onready var identification_section: VBoxContainer = $ScreenMargin/MainLayout/AnswerSection/IdentificationSection
@onready var question_timer: Timer = $QuestionTimer
@onready var exit_confirmation: ConfirmationDialog = $ExitConfirmation

const SOLO_SETUP_PATH: String = "res://scenes/solo/SoloSetup.tscn"
const QUESTION_SECONDS: float = 30.0

var questions: Array[Dictionary] = [
	{
		"type": "MultipleChoice",
		"question": "What is the derivative of x²?",
		"choices": ["x", "2x", "x²", "2"],
		"correct_index": 1,
		"answer": "2x"
	},
	{
		"type": "MultipleChoice",
		"question": "What is the value of 5²?",
		"choices": ["10", "15", "25", "50"],
		"correct_index": 2,
		"answer": "25"
	},
	{
		"type": "Identification",
		"question": "What is the name of a polygon with three sides?",
		"answer": "Triangle"
	}
]

var option_buttons: Array[Button] = []
var current_index: int = 0
var selected_option: int = -1
var score: int = 0
var correct_count: int = 0
var answered: bool = false
var finished: bool = false
var exit_pending: bool = false


func _ready() -> void:
	QuizSession.clear_result()
	option_buttons = [
		btn_option_a,
		btn_option_b,
		btn_option_c,
		btn_option_d
	]

	var group := ButtonGroup.new()
	group.allow_unpress = false

	for i in range(option_buttons.size()):
		var button: Button = option_buttons[i]
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(_on_option_selected.bind(i))

	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	txt_answer.text_changed.connect(_on_answer_changed)
	txt_answer.text_submitted.connect(_on_answer_submitted)

	question_timer.one_shot = true
	question_timer.autostart = false
	question_timer.timeout.connect(_on_question_timeout)

	exit_confirmation.confirmed.connect(_on_exit_confirmed)
	exit_confirmation.canceled.connect(_on_exit_canceled)

	lbl_title.text = "Quiz"
	lbl_subject.text = "Math • Easy"
	lbl_answer_prompt.text = "Your answer"
	btn_exit.text = "Exit Quiz"
	btn_submit.text = "Submit Answer"

	question_progress.min_value = 0
	question_progress.max_value = questions.size()
	question_progress.show_percentage = false

	time_remaining.min_value = 0
	time_remaining.max_value = QUESTION_SECONDS
	time_remaining.show_percentage = false

	load_question()


func _process(_delta: float) -> void:
	if not answered and not finished:
		update_timer_display()


func load_question() -> void:
	question_timer.stop()
	question_timer.paused = false

	answered = false
	selected_option = -1

	var question: Dictionary = questions[current_index]
	var is_multiple_choice: bool = (
		question["type"] == "MultipleChoice"
	)

	lbl_question_text.text = str(question["question"])
	lbl_question_type.text = (
		"MULTIPLE CHOICE"
		if is_multiple_choice
		else "IDENTIFICATION"
	)

	lbl_progess.text = "Question %d of %d" % [
		current_index + 1,
		questions.size()
	]

	question_progress.value = current_index + 1
	lbl_score.text = "Score: %d" % score
	lbl_feedback.text = ""

	multiple_choice_section.visible = is_multiple_choice
	identification_section.visible = not is_multiple_choice

	txt_answer.clear()
	txt_answer.editable = true

	for i in range(option_buttons.size()):
		var button: Button = option_buttons[i]
		button.set_pressed_no_signal(false)
		button.disabled = false

		if is_multiple_choice:
			button.text = "%s. %s" % [
				["A", "B", "C", "D"][i],
				str(question["choices"][i])
			]

	btn_submit.disabled = true
	btn_next.disabled = true
	btn_next.text = (
		"View Results"
		if current_index == questions.size() - 1
		else "Next Question"
	)

	question_timer.start(QUESTION_SECONDS)
	update_timer_display()

	if not is_multiple_choice:
		txt_answer.grab_focus()


func update_timer_display() -> void:
	var seconds_left: float = question_timer.time_left
	lbl_timer.text = "Time: %ds" % int(ceil(seconds_left))
	time_remaining.value = seconds_left


func _on_option_selected(index: int) -> void:
	if answered or finished or exit_pending:
		return

	selected_option = index
	update_submit_button()


func _on_answer_changed(_new_text: String) -> void:
	update_submit_button()


func _on_answer_submitted(_text: String) -> void:
	_on_submit_pressed()


func update_submit_button() -> void:
	if answered or finished or exit_pending:
		btn_submit.disabled = true
		return

	var question: Dictionary = questions[current_index]

	if question["type"] == "MultipleChoice":
		btn_submit.disabled = selected_option == -1
	else:
		btn_submit.disabled = txt_answer.text.strip_edges().is_empty()


func _on_submit_pressed() -> void:
	if answered or finished or exit_pending:
		return

	# Prevent accepting an answer after time has run out.
	if question_timer.time_left <= 0.0:
		finish_question(true)
		return

	update_submit_button()

	if btn_submit.disabled:
		return

	finish_question(false)


func _on_question_timeout() -> void:
	if not answered and not finished:
		finish_question(true)


func finish_question(timed_out: bool) -> void:
	# Stops repeated submissions from awarding points twice.
	if answered or finished:
		return

	answered = true

	var seconds_left: float = question_timer.time_left
	question_timer.stop()

	var question: Dictionary = questions[current_index]
	var is_correct: bool = false

	if not timed_out:
		if question["type"] == "MultipleChoice":
			is_correct = selected_option == int(
				question["correct_index"]
			)
		else:
			is_correct = (
				txt_answer.text.strip_edges().to_lower()
				== str(question["answer"]).strip_edges().to_lower()
			)

	if timed_out:
		lbl_feedback.text = "Time's up! Correct answer: %s" % (
			str(question["answer"])
		)
		seconds_left = 0.0
	elif is_correct:
		correct_count += 1

		# Prototype scoring: 100 base + up to 30 speed points.
		var earned_points: int = 100 + int(floor(seconds_left))
		score += earned_points

		lbl_feedback.text = "Correct! +%d points" % earned_points
	else:
		lbl_feedback.text = "Incorrect. Correct answer: %s" % (
			str(question["answer"])
		)

	lbl_score.text = "Score: %d" % score
	lbl_timer.text = "Time: %ds" % int(ceil(seconds_left))
	time_remaining.value = seconds_left

	for button in option_buttons:
		button.disabled = true

	txt_answer.editable = false
	btn_submit.disabled = true
	btn_next.disabled = false


func _on_next_pressed() -> void:
	if exit_pending:
		return

	if finished:
		return_to_setup()
		return

	if not answered:
		return

	if current_index < questions.size() - 1:
		current_index += 1
		load_question()
	else:
		show_results()


func show_results() -> void:
	question_timer.stop()
	finished = true

	QuizSession.store_result(
		score,
		correct_count,
		questions.size(),
		lbl_subject.text
	)

	var error := get_tree().change_scene_to_file(
		"res://scenes/gameplay/results/Results.tscn"
	)

	if error != OK:
		finished = false
		lbl_feedback.text = (
			"Could not open Results. Check the Results scene path."
		)


func _on_exit_pressed() -> void:
	if finished:
		return_to_setup()
		return

	if exit_pending:
		return

	exit_pending = true
	question_timer.paused = true
	update_submit_button()

	exit_confirmation.dialog_text = (
		"Leave this quiz? Your current attempt will not be saved."
	)
	exit_confirmation.popup_centered()


func _on_exit_canceled() -> void:
	exit_pending = false
	question_timer.paused = false
	update_submit_button()


func _on_exit_confirmed() -> void:
	exit_pending = false
	return_to_setup()


func return_to_setup() -> void:
	var error := get_tree().change_scene_to_file(SOLO_SETUP_PATH)

	if error != OK:
		lbl_feedback.text = "Could not open Solo Setup. Check its scene path."
		question_timer.paused = false
		update_submit_button()
