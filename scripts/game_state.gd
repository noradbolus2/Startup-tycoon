extends Node

signal state_changed

var cash: float = 125000.0
var reputation: int = 85
var employees: int = 4
var companies: int = 1
var research: int = 12
var revenue_per_day: float = 24000.0
var expenses_per_day: float = 11700.0
var product_stage: int = 2
var product_name: String = "Nova Assistant"
var day: int = 1
var buildings: Array[Dictionary] = []
var last_saved_unix: int = 0

func _ready() -> void:
    if buildings.is_empty():
        buildings = [
            {"id":"hq", "name":"Founder HQ", "kind":"hq", "level":2, "pos":Vector2(0, -2), "income":8000.0, "cost":35000.0},
            {"id":"lab", "name":"AI Research Lab", "kind":"lab", "level":1, "pos":Vector2(-4, -1), "income":4200.0, "cost":28000.0},
            {"id":"studio", "name":"Product Studio", "kind":"studio", "level":1, "pos":Vector2(3, 1), "income":3600.0, "cost":24000.0},
            {"id":"hub", "name":"Logistics Hub", "kind":"hub", "level":1, "pos":Vector2(-2, 3), "income":2800.0, "cost":18000.0}
        ]

func notify() -> void:
    state_changed.emit()

func daily_tick() -> void:
    var net := revenue_per_day - expenses_per_day
    cash += net
    day += 1
    research = mini(100, research + 1)
    notify()

func to_dict() -> Dictionary:
    return {"cash":cash, "reputation":reputation, "employees":employees, "companies":companies, "research":research, "revenue_per_day":revenue_per_day, "expenses_per_day":expenses_per_day, "product_stage":product_stage, "product_name":product_name, "day":day, "buildings":buildings, "last_saved_unix":Time.get_unix_time_from_system()}

func from_dict(data: Dictionary) -> void:
    for key in ["cash","reputation","employees","companies","research","revenue_per_day","expenses_per_day","product_stage","product_name","day","buildings","last_saved_unix"]:
        if data.has(key):
            set(key, data[key])
    notify()
