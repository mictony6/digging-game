@tool
extends Control
class_name VitalsArc

var health_ratio: float = 1.0
var oxygen_ratio: float = 1.0

var _wave_time: float = 0.0

const O2_COLOR  := Color(0.22, 0.85, 0.62, 1.0)
const HP_COLOR  := Color(0.88, 0.22, 0.14, 1.0)
const DARK_BG   := Color(0.03, 0.03, 0.05, 0.84)
const GLASS_BG  := Color(0.05, 0.05, 0.08, 1.0)
const BG_RING   := Color(0.20, 0.20, 0.23, 0.88)
const ARC_START := -PI / 2.0
const ARC_PTS   := 64
const OUTER_W   := 10.0
const RING_GAP  := 6.0


func _process(delta: float) -> void:
	_wave_time += delta * 1.8
	queue_redraw()


func _draw() -> void:
	var center  := size * 0.5
	var outer_r := minf(size.x, size.y) * 0.5 - OUTER_W * 0.5 - 2.0
	var inner_r := outer_r - OUTER_W * 0.5 - RING_GAP

	# Dark background disk
	draw_circle(center, outer_r + OUTER_W * 0.5 + 2.0, DARK_BG)

	# Inner glass background
	draw_circle(center, inner_r, GLASS_BG)

	# Health liquid fill
	if health_ratio >= 0.995:
		draw_circle(center, inner_r, HP_COLOR)
	elif health_ratio > 0.005:
		_draw_liquid(center, inner_r)

	# O2 outer ring — track then fill + dot
	draw_arc(center, outer_r, 0.0, TAU, ARC_PTS, BG_RING, OUTER_W, true)
	if oxygen_ratio > 0.001:
		draw_arc(center, outer_r, ARC_START, ARC_START + TAU * oxygen_ratio, ARC_PTS, O2_COLOR, OUTER_W, true)
		var o2_end := ARC_START + TAU * oxygen_ratio
		var o2_dot := center + Vector2(cos(o2_end), sin(o2_end)) * outer_r
		draw_circle(o2_dot, OUTER_W * 0.55, O2_COLOR)
		draw_arc(o2_dot, OUTER_W * 0.55, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.50), 1.0, true)


func _draw_liquid(center: Vector2, r: float) -> void:
	var h          := r * (1.0 - 2.0 * health_ratio)
	h               = clampf(h, -(r - 1.0), r - 1.0)
	var chord_half := sqrt(maxf(r * r - h * h, 0.0))
	var wave_amp   := r * 0.06
	var wave_freq  := TAU / (r * 1.4)
	var n_wave     := 40
	var n_arc      := 40

	if h >= 0.0:
		# ≤ 50% — draw lower circular segment (wave top + short arc through bottom)
		var pts := PackedVector2Array()
		for i in range(n_wave + 1):
			var t      := float(i) / float(n_wave)
			var x      := center.x - chord_half + 2.0 * chord_half * t
			var dx     := x - center.x
			var max_dy := sqrt(maxf(r * r - dx * dx, 0.0))
			var wy     := center.y + h + wave_amp * sin(wave_freq * dx + _wave_time)
			wy          = clampf(wy, center.y - max_dy + 0.5, center.y + max_dy - 0.5)
			pts.append(Vector2(x, wy))
		var ar      := atan2(h, chord_half)
		var al      := atan2(h, -chord_half)
		var arc_end := al if al >= ar else al + TAU   # clockwise through bottom
		for i in range(n_arc + 1):
			var t := float(i) / float(n_arc)
			pts.append(center + Vector2(cos(ar + t * (arc_end - ar)), sin(ar + t * (arc_end - ar))) * r)
		draw_colored_polygon(pts, HP_COLOR)
	else:
		# > 50% — fill entire circle, then erase the small upper cap
		draw_circle(center, r, HP_COLOR)
		var pts := PackedVector2Array()
		for i in range(n_wave + 1):
			var t      := float(i) / float(n_wave)
			var x      := center.x - chord_half + 2.0 * chord_half * t
			var dx     := x - center.x
			var max_dy := sqrt(maxf(r * r - dx * dx, 0.0))
			var wy     := center.y + h + wave_amp * sin(wave_freq * dx + _wave_time)
			wy          = clampf(wy, center.y - max_dy + 0.5, center.y + max_dy - 0.5)
			pts.append(Vector2(x, wy))
		var ar      := atan2(h, chord_half)
		var al      := atan2(h, -chord_half)
		var arc_end := al if al < ar else al - TAU   # counter-clockwise through top
		for i in range(n_arc + 1):
			var t := float(i) / float(n_arc)
			pts.append(center + Vector2(cos(ar + t * (arc_end - ar)), sin(ar + t * (arc_end - ar))) * r)
		draw_colored_polygon(pts, GLASS_BG)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func set_health(current: float, max_val: float) -> void:
	health_ratio = clampf(current / max_val, 0.0, 1.0) if max_val > 0.0 else 0.0
	queue_redraw()


func set_oxygen(current: float, max_val: float) -> void:
	oxygen_ratio = clampf(current / max_val, 0.0, 1.0) if max_val > 0.0 else 0.0
	queue_redraw()
