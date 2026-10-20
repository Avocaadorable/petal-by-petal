extends Control

const OPENING_Y := 0.96
const MAX_STEMS := 6
const STEM_PRICE := 6
const BUDGET := 42
const PETAL_TRIANGLE_BUDGET := 1500
const DESIGN_COLORS := {
	# Match Mina's requested colors to the exact art-bible swatches.
	"Blush": Color("#debfbf"),
	"Cream": Color("#f7ede1"),
	"Lavender": Color("#c592d1"),
}
const DARK_INK := Color("#51443f")
const MUTED_INK := Color("#897871")
const CREAM := Color("#f7ede1")
const PALE_PINK := Color("#debfbf")
const PALE_GREEN := Color("#c4debf")
const SAGE := Color("#7fa377")
const GOLD := Color("#bfa867")

var dialogue := [
	{
		"line": "I’m Mina. Ms. Chen taught art at Linden Primary. I brought our old paint-stained class apron to the reunion by accident.",
		"fact": "Mina was a student at Linden Primary and still keeps the old class apron.",
		"choices": [
			{"text": "What do you miss most about teaching?", "bond": 2},
			{"text": "An apron with stories sounds lovely.", "bond": 1},
			{"text": "It must be nice to see everyone again.", "bond": 1},
		],
	},
	{
		"line": "They’re opening our old art room for one afternoon. My classmates are coming back, and Ms. Chen will be there too. I want the welcome table to feel like coming home.",
		"fact": "Mina and her former classmates are gathering with Ms. Chen in their old art room.",
		"choices": [
			{"text": "What made that room feel like home?", "bond": 2},
			{"text": "I’ll make the table feel warm and welcoming.", "bond": 1},
			{"text": "Did your class have a favorite project?", "bond": 2},
		],
	},
	{
		"line": "We grew cosmos in tins on the windowsill. Dusty pink and cream, I think. A little loose and airy, like the garden we made together.",
		"fact": "Cosmos in dusty pink and cream recall Mina’s class windowsill garden; she prefers a loose, airy arrangement.",
		"choices": [
			{"text": "Dusty pink and cream, with room to breathe?", "bond": 2},
			{"text": "I’ll keep it relaxed, like a little garden.", "bond": 2},
			{"text": "That sounds like a lovely memory to bring back.", "bond": 1},
		],
	},
]

var phase := "conversation"
var dialogue_step := 0
var relationship_points := 0
var revealed_facts: Array[String] = []
var stems: Array[Dictionary] = []
var selected_index := -1
var selected_color_name := "Blush"
var undo_stack: Array[Array] = []
var inventory_dragging := false
var stem_dragging := false
var drag_stem_index := -1
var drag_start_transform: Dictionary = {}
var drag_preview: Label
var feedback_message := "Drag a cosmos from the flower card into Mina’s vase."
var highlight_feedback := false

var world_root: Node3D
var camera: Camera3D
var vase_opening_marker: MeshInstance3D
var viewport: SubViewport
var viewport_container: SubViewportContainer
var editor_panel: Panel
var customer_panel: Panel
var request_panel: Panel
var story_label: Label
var conversation_label: Label
var relationship_label: Label
var choices_container: VBoxContainer
var active_color_label: Label
var count_label: Label
var cost_label: Label
var remaining_label: Label
var editor_status_label: Label
var editor_bar_status_label: Label
var selected_label: Label
var height_slider: HSlider
var tilt_slider: HSlider
var delivered_panel: Panel
var delivered_label: Label
var deliver_button: Button
var remove_button: Button
var undo_button: Button
var rotation_left_button: Button
var rotation_right_button: Button
var flower_texture: Texture2D
var drag_inventory_rect := Rect2()
var arrangement_rect := Rect2()
var height_drag_recorded := false
var tilt_drag_recorded := false
var pointer_position := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().title = "Petal by Petal · Mina’s Commission"
	get_window().size = Vector2i(1920, 1080)
	flower_texture = _make_painterly_texture()
	_build_world()
	_build_interface()
	_refresh_dialogue()
	_refresh_order()
	_refresh_selection_controls()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#c4debf")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# The illustrated shop backdrop is deliberately quiet, leaving the bouquet as the focal point.
	var shop_wash := ColorRect.new()
	shop_wash.position = Vector2(0, 102)
	shop_wash.size = Vector2(1920, 978)
	shop_wash.color = Color("#c4debf")
	shop_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shop_wash)
	var lower_wall := ColorRect.new()
	lower_wall.position = Vector2(0, 970)
	lower_wall.size = Vector2(1920, 110)
	lower_wall.color = Color("#cfaa87")
	lower_wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower_wall)
	for i in range(18):
		var seam := ColorRect.new()
		seam.position = Vector2(i * 115, 970)
		seam.size = Vector2(2, 110)
		seam.color = Color("#bd9677")
		seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(seam)

	var header := _make_panel(self, Rect2(36, 22, 1848, 76), Color("#fffaf4"), Color("#c6aa90"), 18)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/design-bible/logo.png")
	logo.position = Vector2(20, 2)
	logo.size = Vector2(230, 72)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(logo)
	var header_tag := _make_label(header, "FIRST COMMISSION  ·  A QUIET AFTERNOON", Rect2(1176, 20, 620, 32), 16, Color("#927d5a"), true)
	header_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	customer_panel = _make_panel(self, Rect2(36, 116, 340, 930), Color("#f8f1e7"), Color("#c4ad96"), 20)
	editor_panel = _make_panel(self, Rect2(394, 116, 1008, 930), Color("#f3e9dc"), Color("#bfa687"), 20)
	request_panel = _make_panel(self, Rect2(1420, 116, 464, 930), Color("#f8f1e7"), Color("#c4ad96"), 20)
	_build_customer_panel()
	_build_editor_panel()
	_build_request_panel()

	drag_preview = _make_label(self, "✿  Cosmos stem", Rect2(-400, -400, 240, 44), 17, DARK_INK, true)
	drag_preview.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.15))
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.visible = false


func _build_customer_panel() -> void:
	_make_label(customer_panel, "YOUR CUSTOMER", Rect2(24, 18, 290, 27), 15, SAGE, true)
	_make_label(customer_panel, "Mina’s story", Rect2(24, 45, 290, 38), 25, DARK_INK, true)
	var portrait := TextureRect.new()
	portrait.position = Vector2(48, 83)
	portrait.size = Vector2(244, 260)
	var shop_scene: Texture2D = load("res://assets/design-bible/shop-scene.png")
	var customer_portrait := AtlasTexture.new()
	customer_portrait.atlas = shop_scene
	# This crop is the separate pink-dressed customer from the design-bible shop
	# scene. The adult florist stays behind the counter in the main illustration.
	customer_portrait.region = Rect2(334, 182, 206, 278)
	portrait.texture = customer_portrait
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	customer_panel.add_child(portrait)
	var customer_name := _make_label(customer_panel, "Mina Chen", Rect2(30, 344, 280, 34), 24, DARK_INK, true)
	customer_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var descriptor := _make_label(customer_panel, "Former student  ·  flower lover", Rect2(22, 378, 296, 28), 14, MUTED_INK)
	descriptor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relationship_label = _make_label(customer_panel, "♡  Just met", Rect2(22, 408, 296, 27), 16, Color("#b27780"), true)
	relationship_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_draw_divider(customer_panel, 446, 296)
	_make_label(customer_panel, "WHAT YOU’VE LEARNED", Rect2(24, 458, 290, 24), 14, SAGE, true)
	story_label = _make_label(customer_panel, "A former student from Linden Primary has come in with a special reunion order.", Rect2(24, 487, 292, 104), 14, DARK_INK)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conversation_label = _make_label(customer_panel, "", Rect2(23, 597, 294, 117), 16, DARK_INK)
	conversation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choices_container = VBoxContainer.new()
	choices_container.position = Vector2(21, 720)
	choices_container.size = Vector2(298, 202)
	choices_container.add_theme_constant_override("separation", 8)
	customer_panel.add_child(choices_container)


func _build_editor_panel() -> void:
	_make_label(editor_panel, "YOUR SHOP · YOU’RE THE FLORIST", Rect2(24, 18, 420, 24), 14, SAGE, true)
	_make_label(editor_panel, "Arrange at your own pace", Rect2(24, 42, 620, 37), 25, DARK_INK, true)
	var tip := _make_label(editor_panel, "Drag a stem into the vase · drag a bloom to reposition", Rect2(24, 80, 780, 24), 15, MUTED_INK)
	tip.name = "EditorInstructions"
	viewport_container = SubViewportContainer.new()
	viewport_container.position = Vector2(20, 116)
	viewport_container.size = Vector2(968, 590)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	viewport_container.focus_mode = Control.FOCUS_ALL
	var illustrated_shop := TextureRect.new()
	illustrated_shop.texture = load("res://assets/design-bible/shop-scene.png")
	illustrated_shop.position = viewport_container.position
	illustrated_shop.size = viewport_container.size
	illustrated_shop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustrated_shop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	illustrated_shop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	editor_panel.add_child(illustrated_shop)
	editor_panel.add_child(viewport_container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(968, 590)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)
	viewport.add_child(world_root)

	var editor_bar := _make_panel(editor_panel, Rect2(20, 720, 968, 189), Color("#fffaf4"), Color("#e1d4c5"), 16)
	selected_label = _make_label(editor_bar, "No stem selected", Rect2(18, 11, 335, 25), 16, DARK_INK, true)
	undo_button = _make_button(editor_bar, "↶  Undo", Rect2(750, 10, 96, 38), 15, _undo, PALE_GREEN)
	remove_button = _make_button(editor_bar, "Remove", Rect2(852, 10, 98, 38), 15, _remove_selected, PALE_PINK)
	_make_label(editor_bar, "Height", Rect2(18, 51, 85, 24), 14, MUTED_INK, true)
	height_slider = HSlider.new()
	height_slider.position = Vector2(98, 50)
	height_slider.size = Vector2(254, 26)
	height_slider.min_value = 0.75
	height_slider.max_value = 1.35
	height_slider.step = 0.01
	height_slider.value = 1.0
	height_slider.tooltip_text = "Adjust stem height"
	height_slider.drag_started.connect(_on_height_drag_started)
	height_slider.drag_ended.connect(_on_height_drag_ended)
	height_slider.value_changed.connect(_on_height_changed)
	editor_bar.add_child(height_slider)
	_make_label(editor_bar, "Tilt", Rect2(18, 91, 85, 24), 14, MUTED_INK, true)
	tilt_slider = HSlider.new()
	tilt_slider.position = Vector2(98, 90)
	tilt_slider.size = Vector2(254, 26)
	tilt_slider.min_value = -20.0
	tilt_slider.max_value = 20.0
	tilt_slider.step = 1.0
	tilt_slider.value = 0.0
	tilt_slider.tooltip_text = "Adjust stem tilt"
	tilt_slider.drag_started.connect(_on_tilt_drag_started)
	tilt_slider.drag_ended.connect(_on_tilt_drag_ended)
	tilt_slider.value_changed.connect(_on_tilt_changed)
	editor_bar.add_child(tilt_slider)
	_make_label(editor_bar, "Rotate", Rect2(385, 50, 72, 24), 14, MUTED_INK, true)
	rotation_left_button = _make_button(editor_bar, "↶  15°", Rect2(461, 44, 104, 38), 15, func(): _rotate_selected(-15.0), PALE_GREEN)
	rotation_right_button = _make_button(editor_bar, "↷  15°", Rect2(573, 44, 104, 38), 15, func(): _rotate_selected(15.0), PALE_GREEN)
	editor_bar_status_label = _make_label(editor_bar, "Drag a bloom to move it; use the controls to refine its shape.", Rect2(384, 92, 557, 26), 13, MUTED_INK)


func _build_request_panel() -> void:
	_make_label(request_panel, "CUSTOM ORDER", Rect2(24, 18, 390, 25), 14, SAGE, true)
	_make_label(request_panel, "A welcome-table bouquet", Rect2(24, 43, 416, 36), 23, DARK_INK, true)
	_make_label(request_panel, "For Mina’s class reunion", Rect2(24, 82, 414, 25), 15, MUTED_INK)
	var budget_card := _make_panel(request_panel, Rect2(20, 120, 424, 91), Color("#f2e6dc"), Color("#e5d3c2"), 15)
	_make_label(budget_card, "CUSTOMER BUDGET", Rect2(15, 10, 205, 22), 13, MUTED_INK, true)
	_make_label(budget_card, "$42", Rect2(14, 29, 136, 43), 32, DARK_INK, true)
	remaining_label = _make_label(budget_card, "$42 left", Rect2(238, 31, 168, 34), 20, SAGE, true)
	remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_draw_divider(request_panel, 228, 424)
	_make_label(request_panel, "MINA’S REQUEST", Rect2(24, 242, 400, 22), 14, SAGE, true)
	_make_label(request_panel, "Flowers", Rect2(24, 273, 95, 22), 14, MUTED_INK)
	var pref_flower := _make_label(request_panel, "Cosmos", Rect2(143, 270, 274, 28), 17, DARK_INK, true)
	pref_flower.name = "FlowerPreference"
	_make_label(request_panel, "Colors", Rect2(24, 302, 95, 22), 14, MUTED_INK)
	var pref_colors := _make_label(request_panel, "Dusty pink + cream", Rect2(143, 299, 274, 28), 16, DARK_INK, true)
	pref_colors.name = "ColorPreference"
	_make_label(request_panel, "Mood", Rect2(24, 331, 95, 22), 14, MUTED_INK)
	var pref_style := _make_label(request_panel, "Loose and airy", Rect2(143, 328, 274, 28), 16, DARK_INK, true)
	pref_style.name = "StylePreference"
	var hint_card := _make_panel(request_panel, Rect2(20, 365, 424, 75), Color("#e9f0e4"), Color("#d4e2d0"), 14)
	_make_label(hint_card, "A gentle tip", Rect2(14, 8, 390, 21), 13, SAGE, true)
	_make_label(hint_card, "Try 3–5 stems with a little space between blooms.", Rect2(14, 31, 396, 36), 14, DARK_INK)
	_make_label(request_panel, "FLOWER BASKET", Rect2(24, 455, 400, 22), 14, SAGE, true)
	var inventory := _make_panel(request_panel, Rect2(20, 483, 424, 112), Color("#fff4f0"), Color("#ead5cd"), 15)
	drag_inventory_rect = Rect2(1420 + 20 + 14, 116 + 483 + 12, 424 - 28, 88)
	var flower_icon := _make_label(inventory, "✿", Rect2(15, 14, 58, 58), 38, Color("#d7979d"), true)
	flower_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_make_label(inventory, "Cosmos stem", Rect2(82, 12, 223, 25), 18, DARK_INK, true)
	_make_label(inventory, "$6 each  ·  drag to add", Rect2(82, 42, 268, 23), 14, MUTED_INK)
	var color_title := _make_label(request_panel, "PETAL COLOR", Rect2(24, 606, 170, 23), 14, SAGE, true)
	active_color_label = _make_label(request_panel, "Blush selected", Rect2(198, 606, 236, 23), 14, MUTED_INK)
	var swatch_colors: Array[Color] = [DESIGN_COLORS["Blush"], DESIGN_COLORS["Cream"], DESIGN_COLORS["Lavender"]]
	var swatch_names: Array[String] = ["Blush", "Cream", "Lavender"]
	for i in range(swatch_colors.size()):
		var swatch := _make_button(request_panel, "", Rect2(24 + i * 72, 635, 58, 43), 14, func(): _choose_color(swatch_names[i]), swatch_colors[i])
		swatch.tooltip_text = swatch_names[i]
	_make_label(request_panel, "Selected color applies to newly placed stems.", Rect2(24, 682, 410, 24), 13, MUTED_INK)
	_draw_divider(request_panel, 716, 424)
	count_label = _make_label(request_panel, "Arrangement  ·  0 stems", Rect2(24, 731, 410, 26), 16, DARK_INK, true)
	cost_label = _make_label(request_panel, "Materials  ·  $0", Rect2(24, 762, 410, 23), 15, MUTED_INK)
	var status_card := _make_panel(request_panel, Rect2(20, 795, 424, 57), Color("#f4efe5"), Color("#e2d5c4"), 13)
	editor_status_label = _make_label(status_card, feedback_message, Rect2(12, 6, 396, 45), 14, DARK_INK)
	deliver_button = _make_button(request_panel, "Deliver arrangement", Rect2(20, 870, 424, 45), 18, _deliver, Color("#7fa377"), Color("#fffaf4"))
	deliver_button.disabled = true
	delivered_panel = _make_panel(request_panel, Rect2(20, 870, 424, 45), Color("#e8f0e3"), Color("#cbdcc7"), 14)
	delivered_panel.visible = false
	delivered_label = _make_label(delivered_panel, "", Rect2(12, 8, 400, 31), 16, DARK_INK, true)


func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "VaseArrangementWorld"
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#fff1df")
	environment.ambient_light_energy = 0.52
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	world_root.add_child(environment_node)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 3.4, 4.1)
	camera.fov = 35.0
	camera.current = true
	world_root.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0, 1.0, 0), Vector3.UP)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48, -34, 0)
	key_light.light_color = Color("#fff0dd")
	key_light.light_energy = 0.68
	key_light.shadow_enabled = true
	world_root.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-2.2, 2.2, 2.0)
	fill_light.light_color = Color("#e3eddc")
	fill_light.light_energy = 0.18
	fill_light.omni_range = 6.0
	world_root.add_child(fill_light)
	# The surrounding shop illustration is drawn flat in the 2D UI, so the vase
	# and stems stay crisp 3D objects over the art-bible scene.
	var vase := MeshInstance3D.new()
	vase.name = "CeramicVase"
	vase.mesh = _make_vase_mesh()
	vase.position = Vector3(0, 0.0, 0)
	var vase_material := StandardMaterial3D.new()
	# Soft glazed ceramic reads better against the watercolor shop illustration
	# than the dark translucent glass shader, which became a gray blob in-game.
	vase_material.albedo_color = Color("#c49b8f")
	vase_material.roughness = 0.68
	vase_material.metallic = 0.0
	vase_material.clearcoat_enabled = true
	vase_material.clearcoat = 0.08
	vase_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	vase.material_override = vase_material
	world_root.add_child(vase)
	vase_opening_marker = MeshInstance3D.new()
	var opening := TorusMesh.new()
	opening.inner_radius = 0.19
	opening.outer_radius = 0.255
	opening.rings = 24
	opening.ring_segments = 8
	vase_opening_marker.mesh = opening
	vase_opening_marker.position = Vector3(0, OPENING_Y + 0.02, 0)
	var opening_material := StandardMaterial3D.new()
	opening_material.albedo_color = Color("#ddc7ab")
	opening_material.roughness = 0.4
	vase_opening_marker.material_override = opening_material
	world_root.add_child(vase_opening_marker)


func _make_vase_mesh() -> ArrayMesh:
	var profile := PackedVector2Array([
		Vector2(0.00, 0.00), Vector2(0.26, 0.00), Vector2(0.34, 0.06),
		Vector2(0.41, 0.25), Vector2(0.39, 0.43), Vector2(0.28, 0.61),
		Vector2(0.25, 0.74), Vector2(0.30, 0.78), Vector2(0.30, 0.82),
		Vector2(0.23, 0.81), Vector2(0.21, 0.70), Vector2(0.31, 0.49),
		Vector2(0.32, 0.28), Vector2(0.26, 0.13), Vector2(0.00, 0.12),
	])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 32
	for ring in range(profile.size() - 1):
		for side in range(SIDES):
			var a0 := TAU * float(side) / SIDES
			var a1 := TAU * float(side + 1) / SIDES
			var p00 := Vector3(cos(a0) * profile[ring].x, profile[ring].y, sin(a0) * profile[ring].x)
			var p10 := Vector3(cos(a1) * profile[ring].x, profile[ring].y, sin(a1) * profile[ring].x)
			var p01 := Vector3(cos(a0) * profile[ring + 1].x, profile[ring + 1].y, sin(a0) * profile[ring + 1].x)
			var p11 := Vector3(cos(a1) * profile[ring + 1].x, profile[ring + 1].y, sin(a1) * profile[ring + 1].x)
			surface.add_vertex(p00)
			surface.add_vertex(p11)
			surface.add_vertex(p10)
			surface.add_vertex(p00)
			surface.add_vertex(p01)
			surface.add_vertex(p11)
	surface.generate_normals()
	return surface.commit()


func _make_painterly_texture() -> Texture2D:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19770421
	for y in range(512):
		for x in range(512):
			var u := float(x) / 511.0
			var v := float(y) / 511.0
			var vein := absf(sin((u - 0.5) * 86.0 + sin(v * 8.0) * 1.6))
			var brush := sin(x * 0.095 + sin(y * 0.028) * 2.2) * 0.018
			var noise := rng.randf_range(-0.023, 0.023)
			var edge_wash := clampf(1.0 - absf(u - 0.5) * 0.58, 0.67, 1.0)
			var stroke := (0.5 - vein) * 0.018 + brush + noise
			var tone := clampf(edge_wash + stroke, 0.56, 1.05)
			image.set_pixel(x, y, Color(tone, tone * 0.99, tone * 0.95, 1.0))
	return ImageTexture.create_from_image(image)


func _create_flower(color: Color) -> Node3D:
	var flower := Node3D.new()
	flower.name = "CosmosStem"
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.012
	stem_mesh.bottom_radius = 0.019
	stem_mesh.height = 1.24
	stem_mesh.radial_segments = 12
	stem_mesh.rings = 1
	stem.mesh = stem_mesh
	stem.position.y = 0.62
	stem.rotation.z = deg_to_rad(-3.0)
	var green_material := StandardMaterial3D.new()
	green_material.albedo_color = Color("#688d63")
	green_material.roughness = 0.86
	stem.material_override = green_material
	flower.add_child(stem)
	for leaf_index in range(2):
		var leaf := MeshInstance3D.new()
		leaf.mesh = _make_leaf_mesh()
		leaf.position = Vector3(0, 0.42 + leaf_index * 0.23, 0)
		leaf.rotation.y = 0.75 + leaf_index * 2.45
		leaf.rotation.z = deg_to_rad(-16.0 + leaf_index * 7.0)
		leaf.material_override = green_material
		flower.add_child(leaf)
	var petal_material := StandardMaterial3D.new()
	petal_material.albedo_color = color
	petal_material.albedo_texture = flower_texture
	petal_material.roughness = 0.76
	petal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	petal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var center := MeshInstance3D.new()
	var center_mesh := SphereMesh.new()
	center_mesh.radius = 0.07
	center_mesh.height = 0.10
	center_mesh.radial_segments = 12
	center_mesh.rings = 8
	center.mesh = center_mesh
	center.position.y = 1.29
	center.rotation.x = deg_to_rad(34.0)
	var heart_material := StandardMaterial3D.new()
	heart_material.albedo_color = Color("#b98c58")
	heart_material.roughness = 0.9
	center.material_override = heart_material
	flower.add_child(center)
	var petals := MeshInstance3D.new()
	petals.name = "PainterlyPetals"
	petals.mesh = _make_petal_crown()
	petals.material_override = petal_material
	petals.position.y = 1.29
	petals.rotation.x = deg_to_rad(34.0)
	flower.add_child(petals)
	flower.set_meta("color", color)
	flower.set_meta("triangle_budget", PETAL_TRIANGLE_BUDGET)
	flower.set_meta("triangle_count", 776)
	return flower


func _make_petal_crown() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const PETALS := 8
	const LENGTH_SEGMENTS := 6
	const WIDTH_SEGMENTS := 5
	for petal_index in range(PETALS):
		var angle := TAU * float(petal_index) / PETALS
		var radial := Vector3(cos(angle), 0, sin(angle))
		var cross := Vector3(-sin(angle), 0, cos(angle))
		for length_step in range(LENGTH_SEGMENTS):
			var t0 := float(length_step) / LENGTH_SEGMENTS
			var t1 := float(length_step + 1) / LENGTH_SEGMENTS
			for width_step in range(WIDTH_SEGMENTS):
				var s0 := float(width_step) / WIDTH_SEGMENTS * 2.0 - 1.0
				var s1 := float(width_step + 1) / WIDTH_SEGMENTS * 2.0 - 1.0
				var p00 := _petal_point(radial, cross, t0, s0)
				var p10 := _petal_point(radial, cross, t1, s0)
				var p11 := _petal_point(radial, cross, t1, s1)
				var p01 := _petal_point(radial, cross, t0, s1)
				surface.add_vertex(p00)
				surface.add_vertex(p10)
				surface.add_vertex(p11)
				surface.add_vertex(p00)
				surface.add_vertex(p11)
				surface.add_vertex(p01)
	surface.generate_normals()
	return surface.commit()


func _petal_point(radial: Vector3, cross: Vector3, t: float, side: float) -> Vector3:
	var width := sin(t * PI) * 0.048
	var distance := 0.025 + t * 0.27
	var arch := 0.038 * sin(t * PI) + 0.018 * (1.0 - absf(side)) * sin(t * PI)
	return radial * distance + cross * (side * width) + Vector3.UP * arch


func _make_leaf_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 7
	for segment in range(SEGMENTS):
		var t0 := float(segment) / SEGMENTS
		var t1 := float(segment + 1) / SEGMENTS
		var width0 := sin(t0 * PI) * 0.095
		var width1 := sin(t1 * PI) * 0.095
		var p00 := Vector3(-width0, 0.035 * sin(t0 * PI), t0 * 0.46)
		var p01 := Vector3(width0, 0.035 * sin(t0 * PI), t0 * 0.46)
		var p10 := Vector3(-width1, 0.035 * sin(t1 * PI), t1 * 0.46)
		var p11 := Vector3(width1, 0.035 * sin(t1 * PI), t1 * 0.46)
		for point in [p00, p10, p11, p00, p11, p01, p00, p11, p10, p00, p01, p11]:
			surface.add_vertex(point)
	surface.generate_normals()
	return surface.commit()


func _make_panel(parent: Control, rect: Rect2, fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(mini(radius, 10))
	style.shadow_color = Color(0.28, 0.22, 0.17, 0.09)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(panel)
	if rect.size.x >= 320 and rect.size.y >= 500:
		var paper_frame := Control.new()
		paper_frame.set_script(load("res://scripts/paper_frame.gd"))
		paper_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		paper_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(paper_frame)
	return panel


func _make_label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _make_button(parent: Control, text: String, rect: Rect2, font_size: int, callback: Callable, fill: Color, text_color := DARK_INK) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color("#b5aea7"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = fill.darkened(0.09)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.content_margin_left = 9
	normal.content_margin_right = 9
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.06)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.darkened(0.07)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#eeeae3")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _draw_divider(parent: Control, y: float, width: float) -> void:
	var divider := ColorRect.new()
	divider.position = Vector2(22, y)
	divider.size = Vector2(width, 1)
	divider.color = Color("#e8ddd1")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(divider)


func _refresh_dialogue() -> void:
	for child in choices_container.get_children():
		child.queue_free()
	if dialogue_step < dialogue.size():
		var beat: Dictionary = dialogue[dialogue_step]
		conversation_label.text = "“%s”" % beat["line"]
		for choice in beat["choices"]:
			var button := _make_button(choices_container, choice["text"], Rect2(0, 0, 298, 58), 15, func(): _choose_dialogue(choice), Color("#f5e6e1"))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size = Vector2(298, 58)
	else:
		conversation_label.text = "“Thank you. You listened to the little things that made the room ours.”"
		var ready_label := _make_label(choices_container, "Mina’s request is ready beside the vase. Take all the time you need.", Rect2(0, 0, 298, 70), 16, SAGE, true)
		ready_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_story()
	_update_relationship()


func _choose_dialogue(choice: Dictionary) -> void:
	if phase != "conversation" or dialogue_step >= dialogue.size():
		return
	relationship_points += int(choice["bond"])
	revealed_facts.append(dialogue[dialogue_step]["fact"])
	dialogue_step += 1
	if dialogue_step >= dialogue.size():
		if relationship_points >= 5:
			revealed_facts.append("Mina tucked an old class photo in her bag and hopes everyone feels welcome.")
		phase = "arranging"
		feedback_message = "Mina’s request is ready beside the vase. Take your time."
	_refresh_dialogue()
	_refresh_order()


func _enter_arranging() -> void:
	phase = "arranging"
	_refresh_dialogue()


func _update_story() -> void:
	if revealed_facts.is_empty():
		story_label.text = "A former student from Linden Primary has come in with a special reunion order."
	else:
		story_label.text = "  ".join(revealed_facts)


func _update_relationship() -> void:
	if relationship_points >= 5:
		relationship_label.text = "♡♡♡  A lovely connection"
	elif relationship_points >= 3:
		relationship_label.text = "♡♡  Getting closer"
	elif relationship_points > 0:
		relationship_label.text = "♡  A warm start"
	else:
		relationship_label.text = "♡  Just met"


func _refresh_order() -> void:
	if is_instance_valid(count_label):
		var count := stems.size()
		count_label.text = "Arrangement  ·  %d stem%s" % [count, "" if count == 1 else "s"]
		cost_label.text = "Materials  ·  $%d" % (count * STEM_PRICE)
		remaining_label.text = "$%d left" % (BUDGET - count * STEM_PRICE)
		deliver_button.disabled = count == 0 or phase == "delivered"
		if phase == "delivered":
			deliver_button.visible = false
			delivered_panel.visible = true
			var score := _arrangement_score()
			delivered_label.text = "Delivered  ·  %d / 3 preferences" % score
		else:
			deliver_button.visible = true
			delivered_panel.visible = false


func _refresh_selection_controls() -> void:
	var has_selection := selected_index >= 0 and selected_index < stems.size()
	selected_label.text = "Selected stem  ·  %02d" % (selected_index + 1) if has_selection else "No stem selected"
	remove_button.disabled = not has_selection
	undo_button.disabled = undo_stack.is_empty()
	rotation_left_button.disabled = not has_selection
	rotation_right_button.disabled = not has_selection
	height_slider.editable = has_selection
	tilt_slider.editable = has_selection
	if has_selection:
		var item: Dictionary = stems[selected_index]
		height_slider.set_value_no_signal(float(item["height"]))
		tilt_slider.set_value_no_signal(float(item["tilt"]))
	else:
		height_slider.set_value_no_signal(1.0)
		tilt_slider.set_value_no_signal(0.0)
	if is_instance_valid(active_color_label):
		active_color_label.text = "%s selected" % selected_color_name
	if is_instance_valid(editor_status_label):
		editor_status_label.text = feedback_message
	if is_instance_valid(editor_bar_status_label):
		editor_bar_status_label.text = "Drag a bloom to move it; use the controls to refine its shape." if selected_index < 0 else "Bloom selected · move it or adjust height, tilt and rotation."


func _choose_color(color_name: String) -> void:
	selected_color_name = color_name
	feedback_message = "%s selected for new stems." % color_name
	_refresh_selection_controls()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pointer: Vector2 = event.position
		pointer_position = pointer
		if event.pressed:
			if phase == "arranging" and drag_inventory_rect.has_point(pointer):
				inventory_dragging = true
				drag_preview.visible = true
				drag_preview.global_position = pointer + Vector2(15, 15)
				return
			if phase == "arranging" and arrangement_rect.has_point(pointer):
				var local_pointer := pointer - arrangement_rect.position
				var hit_index := _hit_test_stems(local_pointer)
				selected_index = hit_index
				if hit_index >= 0:
					_save_undo()
					stem_dragging = true
					drag_stem_index = hit_index
					drag_start_transform = _snapshot_single(stems[hit_index])
					feedback_message = "Move the selected bloom to find its place."
				else:
					feedback_message = "Drag a cosmos stem from the flower basket into the vase."
				_refresh_selection_controls()
		elif not event.pressed:
			if inventory_dragging:
				if arrangement_rect.has_point(pointer) and phase == "arranging":
					var local_pointer := pointer - arrangement_rect.position
					var world_pos := _pointer_to_vase_point(local_pointer)
					if world_pos != Vector3.INF:
						_add_stem(world_pos)
					else:
						_set_feedback("Drop on the vase opening to place that stem.")
				else:
					_set_feedback("The cosmos is still in the flower basket.")
				inventory_dragging = false
				drag_preview.visible = false
			if stem_dragging:
				stem_dragging = false
				drag_stem_index = -1
				feedback_message = "Stem position saved. Use the controls for height, tilt, and rotation."
				_refresh_selection_controls()
	elif event is InputEventMouseMotion:
		var pointer: Vector2 = event.position
		pointer_position = pointer
		if inventory_dragging:
			drag_preview.global_position = pointer + Vector2(15, 15)
		if stem_dragging and drag_stem_index >= 0 and drag_stem_index < stems.size():
			var local_pointer := pointer - arrangement_rect.position
			var world_pos := _pointer_to_vase_point(local_pointer)
			if world_pos != Vector3.INF:
				stems[drag_stem_index]["node"].position.x = world_pos.x
				stems[drag_stem_index]["node"].position.z = world_pos.z
				stems[drag_stem_index]["position"] = Vector2(world_pos.x, world_pos.z)
				feedback_message = "A little space between blooms helps the airy shape."
				_refresh_selection_controls()


func _hit_test_stems(pointer: Vector2) -> int:
	if not is_instance_valid(camera):
		return -1
	var best_index := -1
	var best_distance := 50.0
	for i in range(stems.size()):
		var item: Dictionary = stems[i]
		var node: Node3D = item["node"]
		var target := node.global_position + Vector3(0, 1.0 * float(item["height"]), 0)
		var screen := camera.unproject_position(target)
		var distance := screen.distance_to(pointer)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _pointer_to_vase_point(pointer: Vector2) -> Vector3:
	var ray_origin := camera.project_ray_origin(pointer)
	var ray_direction := camera.project_ray_normal(pointer)
	var plane := Plane(Vector3.UP, OPENING_Y)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	if intersection == null:
		return Vector3.INF
	var point: Vector3 = intersection
	var radius := Vector2(point.x, point.z).length()
	if radius > 0.235:
		return Vector3.INF
	return Vector3(point.x, OPENING_Y, point.z)


func _add_stem(world_pos: Vector3) -> void:
	if stems.size() >= MAX_STEMS:
		_set_feedback("Mina’s $42 budget covers up to six cosmos stems. You have room for no more.")
		return
	if (stems.size() + 1) * STEM_PRICE > BUDGET:
		_set_feedback("That would go over Mina’s budget. You can rearrange or remove a stem.")
		return
	_save_undo()
	var node := _create_flower(DESIGN_COLORS[selected_color_name])
	world_root.add_child(node)
	node.position = world_pos
	node.position.y = OPENING_Y
	var item := {
		"node": node,
		"color_name": selected_color_name,
		"color": DESIGN_COLORS[selected_color_name],
		"position": Vector2(world_pos.x, world_pos.z),
		"rotation": 0.0,
		"height": 1.0,
		"tilt": 0.0,
	}
	stems.append(item)
	selected_index = stems.size() - 1
	feedback_message = "Cosmos added. You can move it, adjust the stem, or add another."
	_refresh_order()
	_refresh_selection_controls()


func _snapshot_single(item: Dictionary) -> Dictionary:
	return {
		"position": item["position"],
		"rotation": item["rotation"],
		"height": item["height"],
		"tilt": item["tilt"],
		"color_name": item["color_name"],
	}


func _save_undo() -> void:
	var snapshot: Array = []
	for item in stems:
		snapshot.append(_snapshot_single(item))
	undo_stack.append(snapshot)
	if undo_stack.size() > 30:
		undo_stack.pop_front()
	_refresh_selection_controls()


func _undo() -> void:
	if undo_stack.is_empty():
		return
	var snapshot: Array = undo_stack.pop_back()
	for item in stems:
		(item["node"] as Node3D).queue_free()
	stems.clear()
	for saved in snapshot:
		var color_name: String = saved["color_name"]
		var node := _create_flower(DESIGN_COLORS[color_name])
		world_root.add_child(node)
		node.position = Vector3(saved["position"].x, OPENING_Y, saved["position"].y)
		node.rotation = Vector3(0, deg_to_rad(float(saved["rotation"])), deg_to_rad(float(saved["tilt"])))
		node.scale.y = float(saved["height"])
		stems.append({
			"node": node,
			"color_name": color_name,
			"color": DESIGN_COLORS[color_name],
			"position": saved["position"],
			"rotation": saved["rotation"],
			"height": saved["height"],
			"tilt": saved["tilt"],
		})
	selected_index = mini(selected_index, stems.size() - 1)
	feedback_message = "Undone. Your previous composition is back."
	_refresh_order()
	_refresh_selection_controls()


func _remove_selected() -> void:
	if selected_index < 0 or selected_index >= stems.size():
		return
	_save_undo()
	var item: Dictionary = stems[selected_index]
	(item["node"] as Node3D).queue_free()
	stems.remove_at(selected_index)
	selected_index = mini(selected_index, stems.size() - 1)
	feedback_message = "Stem removed. You can undo if you change your mind."
	_refresh_order()
	_refresh_selection_controls()


func _rotate_selected(degrees: float) -> void:
	if selected_index < 0 or selected_index >= stems.size():
		return
	_save_undo()
	var item: Dictionary = stems[selected_index]
	item["rotation"] = fposmod(float(item["rotation"]) + degrees, 360.0)
	(item["node"] as Node3D).rotation.y = deg_to_rad(float(item["rotation"]))
	feedback_message = "Bloom rotated %d°." % roundi(degrees)
	_refresh_selection_controls()


func _on_height_drag_started() -> void:
	if selected_index >= 0 and not height_drag_recorded:
		_save_undo()
		height_drag_recorded = true


func _on_height_drag_ended(_changed: bool) -> void:
	height_drag_recorded = false


func _on_height_changed(value: float) -> void:
	if selected_index < 0 or selected_index >= stems.size():
		return
	var item: Dictionary = stems[selected_index]
	item["height"] = value
	(item["node"] as Node3D).scale.y = value
	feedback_message = "Stem height adjusted."
	_refresh_selection_controls()


func _on_tilt_drag_started() -> void:
	if selected_index >= 0 and not tilt_drag_recorded:
		_save_undo()
		tilt_drag_recorded = true


func _on_tilt_drag_ended(_changed: bool) -> void:
	tilt_drag_recorded = false


func _on_tilt_changed(value: float) -> void:
	if selected_index < 0 or selected_index >= stems.size():
		return
	var item: Dictionary = stems[selected_index]
	item["tilt"] = value
	(item["node"] as Node3D).rotation.z = deg_to_rad(value)
	feedback_message = "Stem tilt adjusted."
	_refresh_selection_controls()


func _set_feedback(message: String) -> void:
	feedback_message = message
	_refresh_selection_controls()


func _arrangement_score() -> int:
	var score := 0
	if stems.size() >= 1:
		score += 1 # The available flower is cosmos, as requested.
	var preferred_colors := 0
	var lavender_count := 0
	for item in stems:
		if item["color_name"] in ["Blush", "Cream"]:
			preferred_colors += 1
		if item["color_name"] == "Lavender":
			lavender_count += 1
	if preferred_colors >= maxi(1, ceili(float(stems.size()) * 0.6)):
		score += 1
	var airy := stems.size() >= 3 and stems.size() <= 5
	if stems.size() > 1:
		var total_distance := 0.0
		var pairs := 0
		for i in range(stems.size()):
			for j in range(i + 1, stems.size()):
				total_distance += Vector2(stems[i]["position"]).distance_to(Vector2(stems[j]["position"]))
				pairs += 1
		airy = airy and (pairs == 0 or total_distance / pairs >= 0.10)
	if airy:
		score += 1
	if lavender_count == stems.size():
		highlight_feedback = true
	return score


func _deliver() -> void:
	if stems.is_empty() or phase == "delivered":
		return
	phase = "delivered"
	var score := _arrangement_score()
	var message := "Mina smiles at the cosmos you chose."
	if score == 3:
		message += " The dusty pink and cream blooms feel just like her windowsill garden, and the airy shape gives every flower room to breathe."
	elif score == 2:
		message += " She recognizes the flowers and colors; she especially likes the way you arranged them."
	else:
		message += " She appreciates the care you put into it. Next time, she might enjoy more of her favorite colors or a looser shape."
	var tip := 0
	if score == 3:
		tip = 8
	elif score == 2:
		tip = 3
	var earned := 18 + tip
	conversation_label.text = "“%s”\n\n%s" % ["I’ll remember this afternoon whenever I look at cosmos.", message]
	feedback_message = "Payment $18  +  $%d tip  =  $%d earned" % [tip, earned]
	_refresh_order()
	_refresh_selection_controls()


func _process(_delta: float) -> void:
	if not is_instance_valid(viewport_container):
		return
	var global_rect := viewport_container.get_global_rect()
	arrangement_rect = global_rect
	# The inventory card is built in the request panel; track it in global canvas coordinates.
	drag_inventory_rect = Rect2(request_panel.global_position + Vector2(34, 495), Vector2(396, 88))
	if inventory_dragging:
		drag_preview.visible = true
		drag_preview.global_position = pointer_position + Vector2(15, 15)

