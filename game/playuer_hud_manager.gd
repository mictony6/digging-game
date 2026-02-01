extends Control

@onready var quota_value_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/QuotaValueLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@export var death_screen: Control
@export var player: Player
@export var eod_screen: Control

func _ready() -> void:
	player.health.health_changed.connect(_on_health_changed)
	player.health.death.connect(_on_player_death)
	player.oxygen.oxygen_changed.connect(_on_oxygen_changed)
	QuotaManager.quota_changed.connect(_on_quota_changed)
	PlayerData.coins_changed.connect(_on_coins_changed)
	quota_value_label.text = "0 / %d" % QuotaManager.required_quota
	progress_bar.max_value = QuotaManager.required_quota
	progress_bar.value = 0
	death_screen.hide()
	eod_screen.hide()
	

func _on_oxygen_changed(current, max_value):
	$OxygenLevel.value = current
	$OxygenLevel.max_value = max_value

func _on_health_changed(current, max_value):
	$HealthDisplay.value = current
	$HealthDisplay.max_value = max_value

func _on_player_death():
	self.hide()
	death_screen.show()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

# to refactor 

func _on_quota_changed(current: int, required: int) -> void:
	quota_value_label.text = "%d / %d" % [current, required]
	progress_bar.value = current

func _on_coins_changed(value: int):
	$CoinAmountLabel.text = "Coins: " + str(value)


func _on_date_manager_day_passed(days: int) -> void:
	self.hide()
	eod_screen.show()
	await get_tree().create_timer(5.0).timeout
	QuotaManager.reset()
	self.show()
	eod_screen.hide()
