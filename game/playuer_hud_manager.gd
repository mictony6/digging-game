extends Control

@export var death_screen: Control
@export var player: Player
@export var eod_screen: Control
@export var inventory_ui: Control
@export var shop_ui: Control

@onready var day_label: Label = %DayLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var oxygen_bar: ProgressBar = %OxygenBar
@onready var health_pct_label: Label = %HealthPctLabel
@onready var quota_pct_label: Label = %QuotaPctLabel
@onready var quota_value_label: Label = %QuotaValueLabel
@onready var info_group: VBoxContainer = %InfoGroup
@onready var coin_label: Label = %CoinLabel
@onready var coin_popup: Label = %CoinPopupLabel
@onready var tool_name_label: Label = %ToolNameLabel
@onready var tool_status_label: Label = %ToolStatusLabel
@onready var durability_bar: ProgressBar = %DurabilityBar
@onready var durability_pct_label: Label = %DurabilityPctLabel
@onready var crosshair: Label = %Crosshair
@onready var _stats_panel: Control    = %PickaxeStatsPanel
@onready var _stat_tier: Label        = %StatTier
@onready var _stat_power: Label       = %StatPower
@onready var _stat_maxdur: Label      = %StatMaxDur

var _pending_report: Dictionary = {}
var _tool_manager: ToolManager

const COLOR_READY  := Color(0.16, 0.84, 0.34, 1.0)
const COLOR_BROKEN := Color(0.90, 0.20, 0.10, 1.0)

# Coin lerp
var _coin_display: float = 0.0
var _coin_target: int = 0

# Info group auto-hide
var _info_hide_timer: float = 0.0
const INFO_SHOW_DURATION := 3.5
var _dur_is_low: bool = false
var _health_is_low: bool = false

# Popup base position
var _popup_base_y: float = 0.0
var _popup_tween: Tween

# Flash tweens
var _health_flash_tween: Tween
var _dur_flash_tween: Tween


func _ready() -> void:
	player.health.health_changed.connect(_on_health_changed)
	player.health.death.connect(_on_player_death)
	player.oxygen.oxygen_changed.connect(_on_oxygen_changed)
	QuotaManager.quota_changed.connect(_on_quota_changed)
	PlayerData.coins_changed.connect(_on_coins_changed)
	DateManager.day_passed.connect(_on_date_manager_day_passed)
	eod_screen.connect("confirmed", _on_eod_confirmed)
	if inventory_ui:
		inventory_ui.visibility_changed.connect(_on_inventory_visibility_changed)
		player.inventory_opened.connect(func(data): inventory_ui.open(data))
		player.inventory_closed.connect(func(): inventory_ui.close())
	if shop_ui:
		shop_ui.visibility_changed.connect(_on_shop_visibility_changed)

	_coin_target = PlayerData.coins
	_coin_display = float(_coin_target)
	coin_label.text = _fmt(_coin_target)
	quota_value_label.text = "0 / %d SC" % QuotaManager.required_quota
	quota_pct_label.text = "0%"
	day_label.text = "DAY %d" % (DateManager.days_passed + 1)

	_tool_manager = player.get_node_or_null("Head/ToolManager") as ToolManager
	if _tool_manager:
		_tool_manager.durability_changed.connect(_on_durability_changed)
		var max_dur: float = _tool_manager._get_max_durability()
		durability_bar.max_value = max_dur
		durability_bar.value = _tool_manager.current_durability
		if _tool_manager.current_tool and _tool_manager.current_tool.tool_data:
			tool_name_label.text = _tool_manager.current_tool.tool_data.name.to_upper()

	info_group.modulate.a = 0.0
	coin_popup.modulate.a = 0.0
	_popup_base_y = coin_popup.position.y

	death_screen.hide()
	eod_screen.hide()


func _process(delta: float) -> void:
	if _stats_panel.visible:
		_refresh_stats()

	# Lerp coin display toward target
	if absf(_coin_display - float(_coin_target)) > 0.5:
		_coin_display = lerpf(_coin_display, float(_coin_target), delta * 8.0)
		coin_label.text = _fmt(int(_coin_display))
	elif int(_coin_display) != _coin_target:
		_coin_display = float(_coin_target)
		coin_label.text = _fmt(_coin_target)

	# Auto-hide info group only when nothing critical and inventory is closed
	if _info_hide_timer > 0.0:
		_info_hide_timer -= delta
		if _info_hide_timer <= 0.0 and not _should_keep_info_visible():
			var t := create_tween()
			t.tween_property(info_group, "modulate:a", 0.0, 1.0)


func _should_keep_info_visible() -> bool:
	if _dur_is_low or _health_is_low:
		return true
	if inventory_ui and inventory_ui.visible:
		return true
	if shop_ui and shop_ui.visible:
		return true
	return false


func _show_info_group() -> void:
	_info_hide_timer = INFO_SHOW_DURATION
	if info_group.modulate.a < 0.95:
		var t := create_tween()
		t.tween_property(info_group, "modulate:a", 1.0, 0.2)


func _force_info_visible() -> void:
	_info_hide_timer = 0.0
	if info_group.modulate.a < 0.95:
		var t := create_tween()
		t.tween_property(info_group, "modulate:a", 1.0, 0.2)


func _on_inventory_visibility_changed() -> void:
	if inventory_ui.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_force_info_visible()
		_refresh_stats()
		_stats_panel.show()
		day_label.show()
		crosshair.hide()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_stats_panel.hide()
		day_label.hide()
		crosshair.show()
		if not _should_keep_info_visible():
			_info_hide_timer = INFO_SHOW_DURATION


func _on_shop_visibility_changed() -> void:
	if shop_ui.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_force_info_visible()
		_refresh_stats()
		_stats_panel.show()
		day_label.show()
		crosshair.hide()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_stats_panel.hide()
		day_label.hide()
		crosshair.show()
		if not _should_keep_info_visible():
			_info_hide_timer = INFO_SHOW_DURATION


func _refresh_stats() -> void:
	if _tool_manager == null or _tool_manager.current_tool == null:
		return
	var td := _tool_manager.current_tool.tool_data
	_stat_tier.text   = str(td.tier + td.tier_upgrade)
	_stat_power.text  = "%.2f" % (td.strength + td.strength_upgrade)
	_stat_maxdur.text = str(int(td.max_durability))


func _on_oxygen_changed(current: float, max_value: float) -> void:
	oxygen_bar.value = current / max_value * 100.0


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.value = current / max_value * 100.0
	health_pct_label.text = "%d%%" % int(current / max_value * 100)
	_health_is_low = (current / max_value) <= 0.25
	if _health_is_low:
		_start_health_flash()
		_force_info_visible()
	else:
		_stop_health_flash()


func _start_health_flash() -> void:
	if _health_flash_tween and _health_flash_tween.is_running():
		return
	_health_flash_tween = create_tween().set_loops()
	_health_flash_tween.tween_property(health_bar, "modulate", Color(2.0, 0.4, 0.3, 1.0), 0.55)
	_health_flash_tween.tween_property(health_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55)


func _stop_health_flash() -> void:
	if _health_flash_tween:
		_health_flash_tween.kill()
		_health_flash_tween = null
	health_bar.modulate = Color.WHITE


func _on_player_death() -> void:
	hide()
	death_screen.show()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func _on_quota_changed(current: int, required: int) -> void:
	quota_value_label.text = "%d / %d SC" % [current, required]
	var pct := int(float(current) / float(required) * 100) if required > 0 else 0
	quota_pct_label.text = "%d%%" % pct


func _on_coins_changed(value: int) -> void:
	var diff := value - _coin_target
	_coin_target = value
	_show_info_group()
	if diff > 0:
		_show_coin_popup(diff)


func _show_coin_popup(amount: int) -> void:
	if _popup_tween:
		_popup_tween.kill()
	coin_popup.text = "+%s" % _fmt(amount)
	coin_popup.position.y = _popup_base_y
	coin_popup.modulate.a = 1.0
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.tween_property(coin_popup, "position:y", _popup_base_y - 38.0, 1.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(coin_popup, "modulate:a", 0.0, 1.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _on_durability_changed(current: float, max_val: float) -> void:
	durability_bar.max_value = max_val
	durability_bar.value = current
	durability_pct_label.text = "%d%%" % int(current / max_val * 100)
	var is_ready := current > 0.0
	tool_status_label.text = "READY" if is_ready else "BROKEN"
	tool_status_label.add_theme_color_override("font_color", COLOR_READY if is_ready else COLOR_BROKEN)
	_dur_is_low = (current / max_val) <= 0.25
	if _dur_is_low:
		_start_dur_flash()
		_force_info_visible()
	else:
		_stop_dur_flash()
		_show_info_group()


func _start_dur_flash() -> void:
	if _dur_flash_tween and _dur_flash_tween.is_running():
		return
	_dur_flash_tween = create_tween().set_loops()
	_dur_flash_tween.tween_property(durability_bar, "modulate", Color(2.0, 0.3, 0.2, 1.0), 0.55)
	_dur_flash_tween.tween_property(durability_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55)


func _stop_dur_flash() -> void:
	if _dur_flash_tween:
		_dur_flash_tween.kill()
		_dur_flash_tween = null
	durability_bar.modulate = Color.WHITE


func _on_date_manager_day_passed(days: int) -> void:
	_pending_report = ExpenseManager.calculate_report(PlayerData.coins_earned_today)
	hide()
	eod_screen.call("show_report", _pending_report, days)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_eod_confirmed() -> void:
	ExpenseManager.confirm_day_end(_pending_report)
	_pending_report = {}
	day_label.text = "DAY %d" % (DateManager.days_passed + 1)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	show()


func _fmt(value: int) -> String:
	if value >= 1000:
		return "%d,%03d" % [int(value / 1000.0), value % 1000]
	return str(value)
