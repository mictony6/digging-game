extends Node
class_name DateManager

var days_passed: int = 0
signal day_passed(days: int)
var minutes_passed: int = 0
var hours_passed: int
var minutes_lenght: float = 5
var timer: Timer

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.start(minutes_lenght)
	timer.timeout.connect(advance_minute)


enum SpecialDays {
	FIRST_DAY = 1,
	TEST_DAY = 3
}
func end_day():
	days_passed += 1
	hours_passed = 0
	day_passed.emit(days_passed)

func start_day():
	if days_passed == SpecialDays.TEST_DAY:
		do_test_day()

func do_test_day():
	pass
func advance_minute():
	minutes_passed += 1
	if minutes_passed == 60:
		minutes_passed = minutes_passed % 60
		hours_passed += 1
	if hours_passed == 24:
		end_day()
	timer.start(minutes_lenght)
