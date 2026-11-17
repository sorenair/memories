extends RefCounted
## Fit the actual memories to the screen; calendar periods label groups rather than empty time.
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

static func positions(count: int, width: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	var margin := clampf(width * 0.07, 28.0, 120.0)
	for index in count:
		result.append(width * 0.5 if count == 1 else lerpf(margin, width - margin, index / float(count - 1)))
	return result

static func build(memories: Array, width: float, font: Font, date_size: int, selected: int) -> Dictionary:
	var marks := positions(memories.size(), width)
	var periods: Array[Dictionary] = []
	var years := {}
	for index in memories.size():
		var memory: Dictionary = memories[index]
		var period := str(memory.get("period", ""))
		var parts := period.split("-")
		var dated := parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int()
		var month := int(parts[1]) if dated else 0
		dated = dated and month >= 1 and month <= 12
		var year := parts[0] if dated else ""
		var text: String = MONTHS[month - 1] if dated else str(memory.get("period_label", "Undated"))
		var key := period if dated else "undated:%d" % index
		if not periods.is_empty() and periods[-1].key == key:
			periods[-1]["last"] = index
		else:
			periods.append({"key": key, "text": text, "year": year, "first": index, "last": index})
		if dated:
			if not years.has(year):
				years[year] = {"text": year, "first": index, "last": index}
			years[year]["last"] = index
	var year_candidates: Array[Dictionary] = []
	var year_starts := PackedInt32Array()
	for year in years.values():
		year_candidates.append(year)
		year_starts.append(year.first)
	var month_candidates: Array[Dictionary] = []
	var months_fit := (width - clampf(width * 0.14, 56.0, 240.0)) / maxf(years.size(), 1) >= 140.0
	for period in periods:
		if months_fit or period.year.is_empty():
			month_candidates.append(period)
	var year_size := clampi(date_size, 18, 28)
	var month_size := clampi(int(date_size * 0.75), 14, 21)
	return {
		"positions": marks, "periods": periods,
		"years": _labels(year_candidates, marks, width, font, year_size, selected, 24.0, true),
		"months": _labels(month_candidates, marks, width, font, month_size, selected, 16.0),
		"year_size": year_size, "month_size": month_size, "year_starts": year_starts,
	}

static func _labels(groups: Array[Dictionary], marks: PackedFloat32Array, width: float, font: Font, font_size: int, selected: int, gap: float, at_start: bool = false) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for index in groups.size():
		var group := groups[index].duplicate()
		var text_width := font.get_string_size(group.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var anchor := marks[group.first] if at_start else (marks[group.first] + marks[group.last]) * 0.5
		var edge := 4.0 if at_start else 12.0
		var center := clampf(anchor, text_width * 0.5 + edge, width - text_width * 0.5 - edge)
		group["x"] = anchor if at_start else center
		group["left"] = center - text_width * 0.5
		group["right"] = center + text_width * 0.5
		group["index"] = group.first if at_start else roundi((group.first + group.last) * 0.5)
		group["priority"] = 100 if selected >= group.first and selected <= group.last else (80 if index == 0 or index == groups.size() - 1 else 10 + group.last - group.first)
		candidates.append(group)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.x < b.x if a.priority == b.priority else a.priority > b.priority)
	var result: Array[Dictionary] = []
	for candidate in candidates:
		var clear := true
		for placed in result:
			if candidate.left < placed.right + gap and candidate.right > placed.left - gap:
				clear = false
				break
		if clear:
			result.append(candidate)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.x < b.x)
	return result
