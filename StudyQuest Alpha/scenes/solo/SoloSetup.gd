extends Control

const QUIZ_PATH: String = "res://Scenes/gameplay/quiz/Quiz.tscn"
const FLASHCARDS_PATH: String = "res://Scenes/gameplay/flashcards/Flashcards.tscn"
const DASHBOARD_PATH: String = "res://Scenes/dashboard/Dashboard.tscn"

@onready var content: VBoxContainer = $MainLayout/ContentMargin/SetupScroll/ContentLayout
@onready var settings: VBoxContainer = content.get_node(
	"SettingsPanel/SettingsMargin/SettingsLayout"
)

@onready var opt_subject: OptionButton = settings.get_node(
	"SubjectSection/optSubject"
)
@onready var opt_difficulty: OptionButton = settings.get_node(
	"DifficultySection/optDifficulty"
)
@onready var question_count: SpinBox = settings.get_node(
	"QuestionCountSection/spnQuestionCount"
)
@onready var lbl_available: Label = settings.get_node(
	"lblAvailableQuestions"
)
@onready var lbl_error: Label = settings.get_node("lblError")

@onready var btn_flashcards: Button = content.get_node(
	"GameTypeCards/FlashcardsCard/FlashcardsMargin/FlashcardsLayout/btnFlashcards"
)
@onready var btn_quiz: Button = content.get_node(
	"GameTypeCards/QuizCard/QuizMargin/QuizLayout/btnQuiz"
)
@onready var btn_start: Button = content.get_node(
	"BottomActions/btnStart"
)
@onready var btn_back: Button = content.get_node(
	"BottomActions/btnBack"
)

var navigating: bool = false


func _ready() -> void:
	fill_options(
		opt_subject,
		QuestionStore.SUBJECTS,
		StudySession.selected_subject
	)
	fill_options(
		opt_difficulty,
		QuestionStore.DIFFICULTIES,
		StudySession.selected_difficulty
	)

	var group := ButtonGroup.new()
	group.allow_unpress = false

	btn_flashcards.toggle_mode = true
	btn_quiz.toggle_mode = true
	btn_flashcards.button_group = group
	btn_quiz.button_group = group

	question_count.step = 1
	question_count.allow_greater = false
	question_count.allow_lesser = false

	btn_flashcards.pressed.connect(select_mode.bind("Flashcards"))
	btn_quiz.pressed.connect(select_mode.bind("Quiz"))
	btn_start.pressed.connect(start_session)
	btn_back.pressed.connect(go_back)

	opt_subject.item_selected.connect(filters_changed)
	opt_difficulty.item_selected.connect(filters_changed)
	question_count.value_changed.connect(count_changed)

	select_mode(StudySession.selected_mode)
	refresh_available()


func fill_options(
	control: OptionButton,
	items: Array,
	saved_value: String
) -> void:
	control.clear()

	for item in items:
		control.add_item(str(item))

	control.select(0)

	for i in range(control.item_count):
		if control.get_item_text(i) == saved_value:
			control.select(i)
			break


func select_mode(mode: String) -> void:
	StudySession.selected_mode = mode

	btn_flashcards.set_pressed_no_signal(mode == "Flashcards")
	btn_quiz.set_pressed_no_signal(mode == "Quiz")

	btn_flashcards.text = (
		"Flashcards Selected" if mode == "Flashcards"
		else "Select Flashcards"
	)
	btn_quiz.text = (
		"Quiz Selected" if mode == "Quiz"
		else "Select Quiz"
	)

	btn_start.text = (
		"Start Flashcards" if mode == "Flashcards"
		else "Start Quiz"
	)


func filters_changed(_index: int) -> void:
	refresh_available()


func refresh_available() -> void:
	StudySession.selected_subject = opt_subject.get_item_text(
		opt_subject.selected
	)
	StudySession.selected_difficulty = opt_difficulty.get_item_text(
		opt_difficulty.selected
	)

	var matches: Array[Dictionary] = StudySession.matching_questions(
		StudySession.selected_subject,
		StudySession.selected_difficulty
	)
	var available: int = matches.size()

	lbl_available.text = "Available questions: %d" % available
	btn_start.disabled = available == 0
	question_count.editable = available > 0

	# Avoid firing value_changed while adjusting the range.
	question_count.set_block_signals(true)
	question_count.min_value = 0
	question_count.max_value = available

	if available > 0:
		question_count.min_value = 1
		question_count.value = clampi(
			StudySession.requested_count, 1, available
		)
	else:
		question_count.value = 0

	question_count.set_block_signals(false)

	if available > 0:
		StudySession.requested_count = int(question_count.value)
		lbl_error.text = ""
	else:
		lbl_error.text = "No matching questions. Choose another subject or difficulty."

	if MockAuth.current_user.is_empty():
		lbl_error.text = "Log in before starting a study session."


func count_changed(value: float) -> void:
	StudySession.requested_count = int(value)


func start_session() -> void:
	if navigating or btn_start.disabled:
		return

	# Commit any number currently being typed into the SpinBox.
	question_count.apply()
	StudySession.requested_count = int(question_count.value)

	if not StudySession.prepare_session():
		refresh_available()
		lbl_error.text = "Could not start. Check the available questions and count."
		return

	QuizSession.clear_result()

	var destination: String = (
		QUIZ_PATH if StudySession.selected_mode == "Quiz"
		else FLASHCARDS_PATH
	)
	navigate_to(destination)


func go_back() -> void:
	navigate_to(DASHBOARD_PATH)


func navigate_to(destination: String) -> void:
	if navigating:
		return

	navigating = true
	var error := get_tree().change_scene_to_file(destination)

	if error != OK:
		navigating = false
		lbl_error.text = "Could not open the screen. Check its scene path."
