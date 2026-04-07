extends Node

# Fixed daily costs — adjust these as you balance the game
const FOOD_COST: int = 15
const ACCOMMODATION_COST: int = 30
const HOSPITAL_BILL: int = 80 # Maria's daily hospital bill
const TOOL_REPAIR_COST: int = 10 # Daily tool wear, scales up when upgrades are added
const TAX_RATE: float = 0.10 # 10% of gross, taken by the company
const QUOTA_BASE_BONUS: int = 1000 # Grows by 1.5x each completed quota

func calculate_report(gross: int) -> Dictionary:
	var tax := roundi(gross * TAX_RATE)
	var fixed := FOOD_COST + ACCOMMODATION_COST + HOSPITAL_BILL + TOOL_REPAIR_COST
	var total_deductions := fixed + tax
	var quota_bonus := 0
	if QuotaManager.quota_met_today:
		quota_bonus = roundi(QUOTA_BASE_BONUS * pow(1.5, QuotaManager.quotas_completed))
	return {
		"gross": gross,
		"food": FOOD_COST,
		"accommodation": ACCOMMODATION_COST,
		"hospital": HOSPITAL_BILL,
		"tool_repair": TOOL_REPAIR_COST,
		"tax": tax,
		"total_deductions": total_deductions,
		"quota_bonus": quota_bonus,
		"net": gross - total_deductions + quota_bonus,
		"wallet_after": PlayerData.coins - total_deductions + quota_bonus,
	}

func apply_deductions(report: Dictionary) -> void:
	PlayerData.coins -= report.total_deductions
	PlayerData.coins += report.quota_bonus
	PlayerData.coins_earned_today = 0
	PlayerData.coins_changed.emit(PlayerData.coins)

# Applies deductions and resets the quota — call this when the player confirms day end.
func confirm_day_end(report: Dictionary) -> void:
	apply_deductions(report)
	QuotaManager.reset()
