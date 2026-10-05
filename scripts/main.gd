extends Node2D

var city: City3DView
var selected: Dictionary = {}
var selected_label: Label
var cash_label: Label
var metrics_label: Label
var action_label: Label

func _ready() -> void:
    EconomyEngine.recalculate(GameState)
    var load_message := SaveManager.load_game(GameState)
    EconomyEngine.recalculate(GameState)
    city = City3DView.new()
    city.name = "CityView"
    add_child(city)
    city.setup(GameState)
    city.building_selected.connect(_on_building_selected)
    build_ui()
    GameState.state_changed.connect(refresh_ui)
    MonetizationService.purchase_result.connect(_on_purchase_result)
    AnalyticsService.track("city_opened", {"day":GameState.day})
    refresh_ui()
    if not load_message.is_empty(): action_label.text = load_message

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
    var top := PanelContainer.new(); top.position = Vector2(16, 12); top.size = Vector2(1120, 72); top.add_theme_stylebox_override("panel", panel_style(Color("#0a1931"), 16)); add_child(top)
    var top_row := HBoxContainer.new(); top_row.add_theme_constant_override("separation", 18); top.add_child(top_row)
    var title := make_label("STARTUP TYCOON\nBUSINESS CITY", 18, Color("#e9f8ff")); title.custom_minimum_size = Vector2(190, 0); top_row.add_child(title)
    cash_label = make_label("", 17, Color("#7dffbd")); cash_label.custom_minimum_size = Vector2(170, 0); top_row.add_child(cash_label)
    metrics_label = make_label("", 13, Color("#b4cee3")); metrics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(metrics_label)
    var save := Button.new(); save.text = "SAVE"; save.custom_minimum_size = Vector2(72, 38); save.pressed.connect(_save); top_row.add_child(save)
    var left := PanelContainer.new(); left.position = Vector2(14, 102); left.size = Vector2(94, 324); left.add_theme_stylebox_override("panel", panel_style(Color(0.03, 0.09, 0.17, 0.92), 14)); add_child(left)
    var nav := VBoxContainer.new(); nav.add_theme_constant_override("separation", 6); left.add_child(nav)
    for item in ["BUILD", "BIZ", "MARKET", "STAFF", "TECH", "EMPIRE"]:
        var b := Button.new(); b.text = item; b.custom_minimum_size = Vector2(72, 38); b.pressed.connect(_on_nav.bind(item)); nav.add_child(b)
    var right := PanelContainer.new(); right.position = Vector2(900, 102); right.size = Vector2(238, 364); right.add_theme_stylebox_override("panel", panel_style(Color(0.03, 0.09, 0.17, 0.94), 14)); add_child(right)
    var stack := VBoxContainer.new(); stack.add_theme_constant_override("separation", 7); right.add_child(stack)
    var header := make_label("CITY COMMAND", 16, Color("#f4fbff")); stack.add_child(header)
    selected_label = make_label("Tap a business building\nto inspect it", 13, Color("#b4cee3")); selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; selected_label.custom_minimum_size = Vector2(205, 60); stack.add_child(selected_label)
    var upgrade := Button.new(); upgrade.text = "UPGRADE"; upgrade.custom_minimum_size = Vector2(205, 36); upgrade.pressed.connect(_upgrade); stack.add_child(upgrade)
    var company := Button.new(); company.text = "CREATE COMPANY  ₹25K"; company.custom_minimum_size = Vector2(205, 32); company.pressed.connect(_create_company); stack.add_child(company)
    var hire := Button.new(); hire.text = "HIRE SPECIALIST  ₹8K"; hire.custom_minimum_size = Vector2(205, 32); hire.pressed.connect(_hire); stack.add_child(hire)
    var develop := Button.new(); develop.text = "DEVELOP PRODUCT"; develop.custom_minimum_size = Vector2(205, 32); develop.pressed.connect(_develop); stack.add_child(develop)
    var tick := Button.new(); tick.text = "CLOSE DAY"; tick.custom_minimum_size = Vector2(205, 32); tick.pressed.connect(_advance_day); stack.add_child(tick)
    var analytics := Button.new(); analytics.text = "ANALYTICS"; analytics.custom_minimum_size = Vector2(205, 32); analytics.pressed.connect(_show_analytics); stack.add_child(analytics)
    var offers := Button.new(); offers.text = "OFFERS / SUPPORT"; offers.custom_minimum_size = Vector2(205, 32); offers.pressed.connect(_show_offers); stack.add_child(offers)
    action_label = make_label("Build your business skyline.", 12, Color("#7ea7c0")); action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; stack.add_child(action_label)
    var bottom := PanelContainer.new(); bottom.position = Vector2(180, 636); bottom.size = Vector2(790, 58); bottom.add_theme_stylebox_override("panel", panel_style(Color(0.02, 0.07, 0.14, 0.94), 18)); add_child(bottom)
    var tabs := HBoxContainer.new(); tabs.alignment = BoxContainer.ALIGNMENT_CENTER; tabs.add_theme_constant_override("separation", 52); bottom.add_child(tabs)
    for item in ["CITY", "COMPANY", "MARKET", "RESEARCH", "EMPIRE"]:
        var t := make_label(item, 14, Color("#d8f4ff")); tabs.add_child(t)

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
        GameState.cash -= cost; selected.level += 1; EconomyEngine.recalculate(GameState); AnalyticsService.record_building_upgrade(selected); action_label.text = "%s upgraded to Level %d." % [selected.name, selected.level]; GameState.notify()
    else: action_label.text = "Need ₹%s more cash." % format_money(cost - GameState.cash)

func _create_company() -> void:
    if GameState.cash >= 25000:
        GameState.cash -= 25000; GameState.companies += 1; GameState.reputation += 2; EconomyEngine.recalculate(GameState); AnalyticsService.track("company_created", {"companies":GameState.companies}); action_label.text = "Nova Labs is now part of your empire."; GameState.notify()
    else: action_label.text = "Create a company needs ₹25K."

func _hire() -> void:
    if GameState.cash >= 8000:
        GameState.cash -= 8000; GameState.employees += 1; EconomyEngine.recalculate(GameState); AnalyticsService.track("employee_hired", {"employees":GameState.employees}); action_label.text = "A new specialist joined your team."; GameState.notify()
    else: action_label.text = "Hiring needs ₹8K."

func _develop() -> void:
    if GameState.research >= 10:
        GameState.research -= 10; GameState.product_stage = mini(5, GameState.product_stage + 1); GameState.revenue_per_day += 2400; AnalyticsService.track("product_developed", {"stage":GameState.product_stage}); action_label.text = "Nova Assistant advanced to stage %d." % GameState.product_stage; GameState.notify()
    else: action_label.text = "Need 10% research progress."

func _advance_day() -> void:
    GameState.daily_tick(); EconomyEngine.recalculate(GameState); AnalyticsService.record_day(GameState); action_label.text = "Day %d closed. Net profit added to cash." % GameState.day

func _save() -> void:
    action_label.text = "Game saved locally." if SaveManager.save_game(GameState) else "Save failed."

func _on_nav(item: String) -> void:
    action_label.text = "%s panel is ready for the next milestone." % item

func _show_analytics() -> void:
    AnalyticsService.track("analytics_viewed", {"day":GameState.day})
    action_label.text = AnalyticsService.summary(GameState)

func _show_offers() -> void:
    AnalyticsService.record_offer_viewed("catalog")
    action_label.text = MonetizationService.offers_summary()

func _on_purchase_result(message: String) -> void:
    action_label.text = message
