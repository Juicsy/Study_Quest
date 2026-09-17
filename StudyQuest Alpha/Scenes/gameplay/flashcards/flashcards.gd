extends Control

@onready var lbl_progress: Label = $ScreenMargin/MainLayout/ProgressSection/lblProgress
@onready var study_progress: ProgressBar = $ScreenMargin/MainLayout/ProgressSection/StudyProgress
@onready var lbl_card_side: Label = $ScreenMargin/MainLayout/CardArea/FlashcardPanel/CardMargin/CardLayout/lblCardSide
@onready var lbl_card_content: Label = $ScreenMargin/MainLayout/CardArea/FlashcardPanel/CardMargin/CardLayout/CardScroll/lblCardContent
@onready var lbl_hint: Label = $ScreenMargin/MainLayout/CardArea/FlashcardPanel/CardMargin/CardLayout/lblHint
@onready var btn_previous: Button = $ScreenMargin/MainLayout/Navigation/btnPrevious
@onready var btn_reveal: Button = $ScreenMargin/MainLayout/Navigation/btnReveal
@onready var btn_next: Button = $ScreenMargin/MainLayout/Navigation/btnNext
@onready var exit_confirmation: ConfirmationDialog = $ExitConfirmation

var cards: Array[Dictionary] = []

var current_index: int = 0
var showing_answer: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cards = StudySession.get_questions("Flashcards")
	current_index = 0
	showing_answer = false

	$ScreenMargin/MainLayout/Header/TitleSection/lblSubject.text = (
		StudySession.subject_label()
	)

	study_progress.min_value = 0
	study_progress.max_value = maxi(cards.size(), 1)
	study_progress.show_percentage = false

	exit_confirmation.dialog_text = "Leave this flashcard session?"

	if not exit_confirmation.confirmed.is_connected(_on_exit_confirmed):
		exit_confirmation.confirmed.connect(_on_exit_confirmed)

	if cards.is_empty():
		lbl_card_content.text = "No flashcards selected."
		lbl_card_side.text = "FLASHCARDS"
		lbl_hint.text = "Exit and choose your settings in Solo Setup."
		lbl_progress.text = "Card 0 of 0"
		study_progress.value = 0
		btn_previous.disabled = true
		btn_next.disabled = true
		btn_reveal.disabled = true
		return

	show_card()


func show_card() -> void:
	showing_answer = false

	lbl_card_content.text = str(cards[current_index]["question"])
	lbl_card_side.text = "QUESTION"
	lbl_hint.text = "[HINT TXT]"
	btn_reveal.text = "Reveal Answer"

	lbl_progress.text = "Card %d of %d" % [
		current_index + 1,
		cards.size()
	]

	study_progress.value = current_index + 1

	btn_previous.disabled = current_index == 0
	btn_next.disabled = current_index == cards.size() - 1


func _on_btn_reveal_button_down() -> void:
	showing_answer = not showing_answer

	if showing_answer:
		lbl_card_content.text = str(cards[current_index]["answer"])
		lbl_card_side.text = "ANSWER"
		lbl_hint.text = "[HINT TXT]"
		btn_reveal.text = "Show Question"
	else:
		lbl_card_content.text = str(cards[current_index]["question"])
		lbl_card_side.text = "QUESTION"
		lbl_hint.text = "[HINT TXT]"
		btn_reveal.text = "Reveal Answer"

func _on_btn_previous_button_down() -> void:
	if current_index > 0:
		current_index -= 1
		show_card()


func _on_btn_next_button_down() -> void:
	if current_index < cards.size() - 1:
		current_index += 1
		show_card()


func _on_btn_exit_button_down() -> void:
	exit_confirmation.popup_centered()


func _on_exit_confirmed() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/solo/SoloSetup.tscn")
	if error != OK:
		lbl_hint.text = "Could not open Solo Setup. Check its scene path."
