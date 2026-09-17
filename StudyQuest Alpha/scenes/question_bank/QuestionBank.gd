extends Control

const EDITOR_PATH: String = "res://scenes/question_bank/QuestionEditor.tscn"
const ROW_SCENE = preload("res://components/question_row/QuestionRow.tscn")
const PAGE_SIZE: int = 5

@onready var content: VBoxContainer = $MainLayout/ContentMargin/ContentLayout
@onready var filters: HBoxContainer = content.get_node("FilterPanel/FilterMargin/FilterLayout")
@onready var list_layout: VBoxContainer = content.get_node("QuestionArea/QuestionListPanel/ListMargin/ListLayout")
@onready var preview: VBoxContainer = content.get_node("QuestionArea/PreviewPanel/PreviewMargin/PreviewLayout")
@onready var preview_content: VBoxContainer = preview.get_node("PreviewScroll/PreviewContent")
@onready var search: LineEdit = filters.get_node("txtSearch")
@onready var subject: OptionButton = filters.get_node("optSubject")
@onready var difficulty: OptionButton = filters.get_node("optDifficulty")
@onready var question_type: OptionButton = filters.get_node("optQuestionType")
@onready var rows: VBoxContainer = list_layout.get_node("QuestionScroll/QuestionRows")
@onready var edit_button: Button = preview.get_node("PreviewActions/btnEditQuestion")
@onready var delete_button: Button = preview.get_node("PreviewActions/btnDeleteQuestion")
@onready var delete_dialog: ConfirmationDialog = $DeleteConfirmation

var filtered: Array[Dictionary] = []
var tab_buttons: Array[Button] = []
var tab_index: int = 0
var page: int = 0
var selected_id: int = -1
var pending_delete_id: int = -1
var row_group: ButtonGroup
var navigating: bool = false


func _ready() -> void:
	fill_filter(subject, "All subjects", QuestionStore.SUBJECTS)
	fill_filter(difficulty, "All difficulties", QuestionStore.DIFFICULTIES)
	fill_filter(question_type, "All types", QuestionStore.TYPES)

	tab_buttons = [
		content.get_node("LibraryTabs/btnMyQuestions"),
		content.get_node("LibraryTabs/btnPublicLibrary"),
		content.get_node("LibraryTabs/btnTeamQuestions")
	]

	var tabs_group := ButtonGroup.new()
	tabs_group.allow_unpress = false

	for i in range(tab_buttons.size()):
		tab_buttons[i].toggle_mode = true
		tab_buttons[i].button_group = tabs_group
		tab_buttons[i].pressed.connect(select_tab.bind(i))

	search.text_changed.connect(_on_search_changed)
	subject.item_selected.connect(_on_filter_changed)
	difficulty.item_selected.connect(_on_filter_changed)
	question_type.item_selected.connect(_on_filter_changed)
	filters.get_node("btnResetFilters").pressed.connect(reset_filters)

	content.get_node("Header/btnAddQuestion").pressed.connect(
		open_editor.bind(-1)
	)
	edit_button.pressed.connect(edit_selected)
	delete_button.pressed.connect(request_delete)
	delete_dialog.confirmed.connect(confirm_delete)

	list_layout.get_node("Pagination/btnPreviousPage").pressed.connect(
		change_page.bind(-1)
	)
	list_layout.get_node("Pagination/btnNextPage").pressed.connect(
		change_page.bind(1)
	)

	selected_id = QuestionStore.selected_id
	tab_buttons[0].set_pressed_no_signal(true)
	apply_filters()


func fill_filter(control: OptionButton, heading: String, items: Array) -> void:
	control.clear()
	control.add_item(heading)
	for item in items:
		control.add_item(str(item))
	control.select(0)


func select_tab(index: int) -> void:
	tab_index = index
	selected_id = -1
	page = 0
	apply_filters()


func _on_search_changed(_text: String) -> void:
	page = 0
	apply_filters()


func _on_filter_changed(_index: int) -> void:
	page = 0
	apply_filters()


func reset_filters() -> void:
	search.text = ""
	subject.select(0)
	difficulty.select(0)
	question_type.select(0)
	page = 0
	apply_filters()


func matches_filter(control: OptionButton, value: String) -> bool:
	return (
		control.selected == 0
		or control.get_item_text(control.selected) == value
	)


func apply_filters() -> void:
	filtered.clear()
	var query: String = search.text.strip_edges().to_lower()

	for question in QuestionStore.questions:
		if not QuestionStore.can_view(question):
			continue

		if tab_index == 0:
			if int(question["owner_id"]) != QuestionStore.current_user_id:
				continue
		elif tab_index == 1:
			if question["visibility"] != "Public":
				continue
		else:
			if question["visibility"] != "Team-only":
				continue
			if not QuestionStore.belongs_to_team(int(question["team_id"])):
				continue

		# Only filter by search text when the user has typed something.
		if not query.is_empty():
			if not str(question["question"]).to_lower().contains(query):
				continue
		if not matches_filter(subject, str(question["subject"])):
			continue
		if not matches_filter(difficulty, str(question["difficulty"])):
			continue
		if not matches_filter(question_type, str(question["type"])):
			continue

		filtered.append(question)

	# Bring the saved/selected question into view.
	for i in range(filtered.size()):
		if int(filtered[i]["id"]) == selected_id:
			page = int(i / float(PAGE_SIZE))
			break

	render_page()


func page_count() -> int:
	return maxi(1, int(ceil(float(filtered.size()) / PAGE_SIZE)))


func change_page(direction: int) -> void:
	page = clampi(page + direction, 0, page_count() - 1)
	selected_id = -1
	render_page()


func render_page() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()

	row_group = ButtonGroup.new()
	row_group.allow_unpress = false

	page = clampi(page, 0, page_count() - 1)
	var start: int = page * PAGE_SIZE
	var end: int = mini(start + PAGE_SIZE, filtered.size())

	var selection_on_page: bool = false
	for i in range(start, end):
		if int(filtered[i]["id"]) == selected_id:
			selection_on_page = true

	if not selection_on_page:
		selected_id = int(filtered[start]["id"]) if start < end else -1

	for i in range(start, end):
		var row = ROW_SCENE.instantiate()
		rows.add_child(row)
		row.button_group = row_group
		row.set_question(filtered[i])
		row.set_pressed_no_signal(int(filtered[i]["id"]) == selected_id)
		row.question_selected.connect(select_question)

	list_layout.get_node("ListHeader/lblListTitle").text = [
		"My Questions", "Public Library", "Team Questions"
	][tab_index]
	list_layout.get_node("ListHeader/lblQuestionCount").text = (
		"%d questions" % filtered.size()
	)

	var empty: Label = list_layout.get_node("lblEmptyState")
	empty.text = "No matching questions."
	empty.visible = filtered.is_empty()

	list_layout.get_node("Pagination/lblPageInfo").text = (
		"0 questions" if filtered.is_empty()
		else "%d–%d of %d" % [start + 1, end, filtered.size()]
	)
	list_layout.get_node("Pagination/lblCurrentPage").text = (
		"%d / %d" % [page + 1, page_count()]
	)
	list_layout.get_node("Pagination/btnPreviousPage").disabled = page == 0
	list_layout.get_node("Pagination/btnNextPage").disabled = (
		page == page_count() - 1
	)

	select_question(selected_id)


func select_question(id: int) -> void:
	selected_id = id
	QuestionStore.selected_id = id

	var question: Dictionary = QuestionStore.get_question(id)
	var available: bool = not question.is_empty()

	preview_content.visible = available
	edit_button.disabled = not QuestionStore.can_edit(id)
	delete_button.disabled = not QuestionStore.can_edit(id)

	preview.get_node("lblPreviewTitle").text = (
		"QUESTION PREVIEW" if available else "Select a question"
	)

	if not available:
		return

	preview_content.get_node("Tags/lblSubject").text = str(question["subject"])
	preview_content.get_node("Tags/lblDifficulty").text = str(question["difficulty"])
	preview_content.get_node("Tags/lblVisibility").text = str(question["visibility"])
	preview_content.get_node("lblQuestionText").text = str(question["question"])

	var multiple_choice: bool = question["type"] == "Multiple Choice"
	preview_content.get_node("Choices").visible = multiple_choice
	preview_content.get_node("IdentificationAnswer").visible = not multiple_choice

	if multiple_choice:
		for i in range(4):
			var letter: String = ["A", "B", "C", "D"][i]
			var label: Label = preview_content.get_node(
				"Choices/lblChoice%s" % letter
			)
			var suffix: String = (
				"  ✓ Correct" if i == int(question["correct_index"]) else ""
			)
			label.text = "%s. %s%s" % [
				letter, str(question["choices"][i]), suffix
			]
	else:
		preview_content.get_node(
			"IdentificationAnswer/lblCorrectAnswer"
		).text = str(question["answer"])

	preview_content.get_node("Metadata/lblQuestionType").text = (
		"Type: %s" % question["type"]
	)
	var creator_name: String = QuestionStore.get_creator_name(question)

	if int(question["owner_id"]) == QuestionStore.current_user_id:
		creator_name = "You (%s)" % creator_name

	preview_content.get_node("Metadata/lblCreatedBy").text = (
		"Created by: %s" % creator_name
	)

func edit_selected() -> void:
	if QuestionStore.can_edit(selected_id):
		open_editor(selected_id)


func open_editor(id: int) -> void:
	if navigating:
		return
	if id != -1 and not QuestionStore.can_edit(id):
		return

	navigating = true
	QuestionStore.editing_id = id

	var error := get_tree().change_scene_to_file(EDITOR_PATH)
	if error != OK:
		navigating = false
		QuestionStore.editing_id = -1
		preview.get_node("lblPreviewTitle").text = (
			"Could not open editor. Check EDITOR_PATH."
		)


func request_delete() -> void:
	if not QuestionStore.can_edit(selected_id):
		return

	pending_delete_id = selected_id
	delete_dialog.dialog_text = "Delete this question?"
	delete_dialog.popup_centered()


func confirm_delete() -> void:
	if QuestionStore.delete_question(pending_delete_id):
		selected_id = -1
		apply_filters()
	pending_delete_id = -1
