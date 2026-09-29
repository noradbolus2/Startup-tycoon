extends Node2D

var city: CityView
var selected: Dictionary = {}
var selected_label: Label
var cash_label: Label
var metrics_label: Label
var action_label: Label

func _ready() -> void:
    EconomyEngine.recalculate(GameState)
    SaveManager.load_game(GameState)
    EconomyEngine.recalculate(GameState)
    city = CityView.new()
    city.name = "CityView"
    add_child(city)
    city.setup(GameState)
    city.building_selected.connect(_on_building_selected)
    build_ui()
    GameState.state_changed.connect(refresh_ui)
    refresh_ui()

func make_label(text: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    return label

func panel_style(color: Color, radius := 12) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius; style.corner_radius_top_right = radius; style.corner_radius_bottom_left = radius; style.corner_radius_bottom_right = radius
    style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
    style.border_color = Color(0.3, 0.65, 0.85, 0.45)
    style.content_margin_left = 14; style.content_margin_right = 14; style.content_margin_top = 10; style.content_margin_bottom = 10
    return style

func build_ui() -> void:
    var top := PanelContainer.new(); top.position = Vector2(18, 14); top.size = Vector2(1116, 82); top.add_theme_stylebox_override("panel", panel_style(Color("#0d1d39"), 16)); add_child(top)
    var top_row := HBoxContainer.new(); top_row.add_theme_constant_override("separation", 22); top.add_child(top_row)
    var title := make_label("STARTUP TYCOON\nStart Small. Build Smart. Own the Market.", 21, Color("#e9f8ff")); title.custom_minimum_size = Vector2(310, 0); top_row.add_child(title)
    cash_label = make_label("", 18, Color("#7dffbd")); cash_label.custom_minimum_size = Vector2(200, 0); top_row.add_child(cash_label)
    metrics_label = make_label("", 15, Color("#b4cee3")); metrics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(metrics_label)
    var save := Button.new(); save.text = "SAVE"; save.custom_minimum_size = Vector2(90, 42); save.pressed.connect(_save); top_row.add_child(save)
    var left := PanelContainer.new(); left.position = Vector2(18, 112); left.size = Vector2(130, 450); left.add_theme_stylebox_override("panel", panel_style(Color("#0b1931"), 14)); add_child(left)
    var nav := VBoxContainer.new(); nav.add_theme_constant_override("separation", 10); left.add_child(nav)
    for item in ["BUILD CITY", "COMPANIES", "MARKET", "EMPLOYEES", "RESEARCH", "FINANCE", "EMPIRE"]:
        var b := Button.new(); b.text = item; b.custom_minimum_size = Vector2(102, 42); b.pressed.connect(_on_nav.bind(item)); nav.add_child(b)
    var right := PanelContainer.new(); right.position = Vector2(894, 112); right.size = Vector2(240, 450); right.add_theme_stylebox_override("panel", panel_style(Color("#0b1931"), 14)); add_child(right)
    var stack := VBoxContainer.new(); stack.add_theme_constant_override("separation", 10); right.add_child(stack)
    var header := make_label("BUILD & MANAGE", 17, Color("#f4fbff")); stack.add_child(header)
    selected_label = make_label("Select a building in the city", 14, Color("#b4cee3")); selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; selected_label.custom_minimum_size = Vector2(200, 80); stack.add_child(selected_label)
    var upgrade := Button.new(); upgrade.text = "UPGRADE SELECTED"; upgrade.custom_minimum_size = Vector2(210, 46); upgrade.pressed.connect(_upgrade); stack.add_child(upgrade)
    var company := Button.new(); company.text = "CREATE COMPANY  ₹25K"; company.pressed.connect(_create_company); stack.add_child(company)
    var hire := Button.new(); hire.text = "HIRE EMPLOYEE  ₹8K"; hire.pressed.connect(_hire); stack.add_child(hire)
    var develop := Button.new(); develop.text = "DEVELOP PRODUCT"; develop.pressed.connect(_develop); stack.add_child(develop)
    var tick := Button.new(); tick.text = "ADVANCE 1 DAY"; tick.pressed.connect(_advance_day); stack.add_child(tick)
    action_label = make_label("Tip: build and upgrade to grow revenue.", 13, Color("#7ea7c0")); action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; stack.add_child(action_label)
    var bottom := PanelContainer.new(); bottom.position = Vector2(240, 612); bottom.size = Vector2(654, 70); bottom.add_theme_stylebox_override("panel", panel_style(Color("#09152a"), 18)); add_child(bottom)
    var tabs := HBoxContainer.new(); tabs.alignment = BoxContainer.ALIGNMENT_CENTER; tabs.add_theme_constant_override("separation", 44); bottom.add_child(tabs)
    for item in ["CITY", "BUSINESS", "MARKET", "RESEARCH", "EMPIRE"]:
        var t := make_label(item, 15, Color("#d8f4ff")); tabs.add_child(t)

func refresh_ui() -> void:
    if not is_instance_valid(cash_label): return
    cash_label.text = "₹%s\n+₹%s / day" % [format_money(GameState.cash), format_money(GameState.revenue_per_day - GameState.expenses_per_day)]
    metrics_label.text = "EMPLOYEES  %d     COMPANIES  %d     REPUTATION  %d     RESEARCH  %d%%\nPRODUCT  %s" % [GameState.employees, GameState.companies, GameState.reputation, GameState.research, GameState.product_name]
    if not selected.is_empty(): selected_label.text = "%s\nLevel %d  •  ₹%s/day\nUpgrade cost: ₹%s" % [selected.name, selected.level, format_money(EconomyEngine.building_income(selected)), format_money(EconomyEngine.upgrade_cost(selected))]

func format_money(amount: float) -> String:
    if amount >= 1000000: return "%.1fM" % (amount / 1000000.0)
    if amount >= 1000: return "%.1fK" % (amount / 1000.0)
    return str(int(amount))

func _on_building_selected(building: Dictionary) -> void:
    selected = building
    refresh_ui()

func _upgrade() -> void:
    if selected.is_empty(): action_label.text = "Select a building first."; return
    var cost := EconomyEngine.upgrade_cost(selected)
    if GameState.cash >= cost:
        GameState.cash -= cost; selected.level += 1; EconomyEngine.recalculate(GameState); action_label.text = "%s upgraded to Level %d." % [selected.name, selected.level]; GameState.notify()
    else: action_label.text = "Need ₹%s more cash." % format_money(cost - GameState.cash)

func _create_company() -> void:
    if GameState.cash >= 25000:
        GameState.cash -= 25000; GameState.companies += 1; GameState.reputation += 2; EconomyEngine.recalculate(GameState); action_label.text = "Nova Labs is now part of your empire."; GameState.notify()
    else: action_label.text = "Create a company needs ₹25K."

func _hire() -> void:
    if GameState.cash >= 8000:
        GameState.cash -= 8000; GameState.employees += 1; EconomyEngine.recalculate(GameState); action_label.text = "A new specialist joined your team."; GameState.notify()
    else: action_label.text = "Hiring needs ₹8K."

func _develop() -> void:
    if GameState.research >= 10:
        GameState.research -= 10; GameState.product_stage = mini(5, GameState.product_stage + 1); GameState.revenue_per_day += 2400; action_label.text = "Nova Assistant advanced to stage %d." % GameState.product_stage; GameState.notify()
    else: action_label.text = "Need 10% research progress."

func _advance_day() -> void:
    GameState.daily_tick(); EconomyEngine.recalculate(GameState); action_label.text = "Day %d closed. Net profit added to cash." % GameState.day

func _save() -> void:
    action_label.text = "Game saved locally." if SaveManager.save_game(GameState) else "Save failed."

func _on_nav(item: String) -> void:
    action_label.text = "%s panel is ready for the next milestone." % item
