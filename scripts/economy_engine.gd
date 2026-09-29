class_name EconomyEngine
extends RefCounted

static func building_income(building: Dictionary) -> float:
    return float(building.get("income", 0.0)) * (1.0 + (int(building.get("level", 1)) - 1) * 0.55)

static func upgrade_cost(building: Dictionary) -> float:
    return float(building.get("cost", 10000.0)) * (1.0 + int(building.get("level", 1)) * 0.8)

static func recalculate(state: Node) -> void:
    var revenue := 0.0
    for building in state.buildings:
        revenue += building_income(building)
    revenue += state.employees * 850.0
    state.revenue_per_day = revenue
    state.expenses_per_day = 3500.0 + state.employees * 2050.0 + state.companies * 900.0
