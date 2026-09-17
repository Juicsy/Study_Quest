extends Control

const QUIZ_PATH: String = "res://scenes/gameplay/quiz/Quiz.tscn"
const SOLO_SETUP_PATH: String = "res://scenes/solo/SoloSetup.tscn"
const DASHBOARD_PATH: String = "res://scenes/dashboard/Dashboard.tscn"


@onready var main_layout: VBoxContainer = $ScreenMargin/ResultsScroll/MainLayout
@onready var lbl_title: Label = $ScreenMargin/ResultsScroll/MainLayout/Header/lblTitle
@onready var lbl_subtitle: Label = $ScreenMargin/ResultsScroll/MainLayout/Header/lblSubtitle
@onready var lbl_subject: Label = $ScreenMargin/ResultsScroll/MainLayout/Header/lblSubject
@onready var lbl_score: Label = $ScreenMargin/ResultsScroll/MainLayout/ScorePanel/ScoreMargin/ScroeLayout/lblScore
@onready var lbl_accuracy: Label = $ScreenMargin/ResultsScroll/MainLayout/ScorePanel/ScoreMargin/ScroeLayout/lblAccuracy
@onready var accuracy_bar: ProgressBar = $ScreenMargin/ResultsScroll/MainLayout/ScorePanel/ScoreMargin/ScroeLayout/AccuracyBar
@onready var lbl_total_questions: Label = $ScreenMargin/ResultsScroll/MainLayout/StatisticsPanel/StatisticsMargin/StatisticsGrid/lblTotalQuestions
@onready var lbl_correct_answers: Label = $ScreenMargin/ResultsScroll/MainLayout/StatisticsPanel/StatisticsMargin/StatisticsGrid/lblCorrectAnswers
@onready var lbl_incorrect_answers: Label = $ScreenMargin/ResultsScroll/MainLayout/StatisticsPanel/StatisticsMargin/StatisticsGrid/lblIncorrectAnswers
@onready var lbl_save_status: Label = $ScreenMargin/ResultsScroll/MainLayout/lblSaveStatus
@onready var btn_try_again: Button = $ScreenMargin/ResultsScroll/MainLayout/BottomActions/btnTryAgain
@onready var btn_change_settings: Button = $ScreenMargin/ResultsScroll/MainLayout/BottomActions/btnChangeSettings
@onready var btn_dashboard: Button = $ScreenMargin/ResultsScroll/MainLayout/BottomActions/btnDashboard


var navigating: bool = false

func _ready() -> void:
	btn_try_again.pressed.connect(_on_try_again_pressed)
	btn_change_settings.pressed.connect(_on_change_settings_pressed)
	btn_dashboard.pressed.connect(_on_dashboard_pressed)

	accuracy_bar.min_value = 0
	accuracy_bar.max_value = 100
	accuracy_bar.show_percentage = false

	display_results()


func display_results() -> void:
	# Handles running Results directly with F6.
	if not QuizSession.has_result:
		lbl_title.text = "No Results Yet"
		lbl_subtitle.text = "Complete a quiz to see your results."
		lbl_subject.text = ""

		lbl_score.text = "—"
		lbl_accuracy.text = "Accuracy: —"
		accuracy_bar.value = 0

		lbl_total_questions.text = "—"
		lbl_correct_answers.text = "—"
		lbl_incorrect_answers.text = "—"

		lbl_save_status.text = "No completed attempt is available."
		btn_try_again.disabled = true
		return

	var total: int = QuizSession.total_questions
	var correct: int = QuizSession.correct_answers
	var incorrect: int = total - correct
	var accuracy: float = 0.0

	if total > 0:
		accuracy = float(correct) / float(total) * 100.0

	lbl_title.text = "Quiz Complete!"
	lbl_subtitle.text = "Every attempt helps you learn."
	lbl_subject.text = QuizSession.subject_text

	lbl_score.text = str(QuizSession.score)
	lbl_accuracy.text = "Accuracy: %.1f%%" % accuracy
	accuracy_bar.value = accuracy

	lbl_total_questions.text = str(total)
	lbl_correct_answers.text = str(correct)
	lbl_incorrect_answers.text = str(incorrect)

	lbl_save_status.text = "Practice results only — not saved yet."
	btn_try_again.disabled = false


func _on_try_again_pressed() -> void:
	navigate_to(QUIZ_PATH)


func _on_change_settings_pressed() -> void:
	navigate_to(SOLO_SETUP_PATH)


func _on_dashboard_pressed() -> void:
	navigate_to(DASHBOARD_PATH)


func navigate_to(scene_path: String) -> void:
	if navigating:
		return

	navigating = true

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		navigating = false
		lbl_save_status.text = (
			"Could not open the screen. Check its scene path."
		)
	else:
		QuizSession.clear_result()
