extends Control
class_name DayEndScreen

signal confirmed

@onready var day_label: Label = %DayLabel
@onready var ore_value: Label = %OreValue
@onready var quota_bonus_row: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuotaBonusRow
@onready var quota_bonus_value: Label = %QuotaBonusValue
@onready var food_value: Label = %FoodValue
@onready var accommodation_value: Label = %AccommodationValue
@onready var hospital_value: Label = %HospitalValue
@onready var tool_repair_value: Label = %ToolRepairValue
@onready var tax_value: Label = %TaxValue
@onready var total_value: Label = %TotalValue
@onready var net_label: Label = %NetLabel
@onready var wallet_label: Label = %WalletLabel
@onready var next_btn: Button = %NextBtn

func _ready() -> void:
	next_btn.pressed.connect(_on_next_day_pressed)
	hide()

func show_report(report: Dictionary, day_number: int) -> void:
	day_label.text = "DAY %d" % day_number
	ore_value.text = "+%d c" % report.gross
	if report.quota_bonus > 0:
		quota_bonus_row.show()
		quota_bonus_value.text = "+%d c" % report.quota_bonus
	else:
		quota_bonus_row.hide()
	food_value.text = "-%d c" % report.food
	accommodation_value.text = "-%d c" % report.accommodation
	hospital_value.text = "-%d c" % report.hospital
	tool_repair_value.text = "-%d c" % report.tool_repair
	tax_value.text = "-%d c" % report.tax
	total_value.text = "-%d c" % report.total_deductions

	var net_sign := "+" if report.net >= 0 else ""
	net_label.text = "NET THIS DAY      %s%d c" % [net_sign, report.net]
	net_label.modulate = Color.RED if report.net < 0 else Color.WHITE

	wallet_label.text = "WALLET TOTAL    %d c" % report.wallet_after

	show()

func _on_next_day_pressed() -> void:
	hide()
	confirmed.emit()
