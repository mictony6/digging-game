extends StaticBody3D


func _on_is_selectable_selected() -> void:
	var score = QuotaManager.current_quota
	var coins_got = round(_exchange(score, QuotaManager.exchange_rate))
	PlayerData.add_coins(coins_got)


func _exchange(value: int, rate: float):
	QuotaManager.reset()
	return value * rate
