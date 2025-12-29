extends Control

@onready var quota_value_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/QuotaValueLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	QuotaManager.quota_changed.connect(_on_quota_changed)
	PlayerData.coins_changed.connect(_on_coins_changed)
	PlayerData.oxygen_changed.connect(_on_oxygen_changed)
	quota_value_label.text = "0 / %d" % QuotaManager.required_quota
	progress_bar.max_value = QuotaManager.required_quota
	progress_bar.value = 0
	

func _on_quota_changed(current: int, required: int) -> void:
	quota_value_label.text = "%d / %d" % [current, required]
	progress_bar.value = current

func _on_coins_changed(value: int):
	$CoinAmountLabel.text = "Coins: " + str(value)

func _on_oxygen_changed():
	$OxygenLevel.value = PlayerData.oxygen_remaining;