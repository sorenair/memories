extends Node
## The HUD requests a finite hint. Discovering or reading a fragment never starts one.
signal guidance_started(fragment: MemoryFragment)
const GUIDE = preload("res://components/guidance/brushstroke/fragment_brushstroke_guide.tscn")
const PLANNER = preload("res://components/guidance/brushstroke/brushstroke_route_planner.gd")

@export var actor: Node3D
@export var memory: MemoryScene
@export var button: Control
@export var input_gate: Node

var active_guide: FragmentBrushstrokeGuide
var active_destination: MemoryFragment
var _fallback: FragmentBrushstrokeGuide
var _fragments: Array[MemoryFragment] = []
var _connected: Dictionary = {}
var _finished: Dictionary = {}
var _planner := PLANNER.new()

func _ready() -> void:
	if is_instance_valid(button): button.action_requested.connect(request_guidance)
	get_tree().node_added.connect(_node_added)
	get_tree().node_removed.connect(_node_removed)
	refresh_fragments.call_deferred()

func refresh_fragments() -> void:
	# The inherited world's Memory instance may be added after base-node exports resolve.
	if not is_instance_valid(memory): memory = get_parent().get_node_or_null("Memory") as MemoryScene
	_fragments.clear()
	if is_instance_valid(memory):
		_fragments.assign(memory.get_guidance_fragments())
	for fragment in _fragments:
		var id := fragment.get_instance_id()
		if _connected.has(id): continue
		_connected[id] = true
		_finished[id] = fragment.state == MemoryFragment.State.DECAYING
		fragment.state_changed.connect(_fragment_state.bind(fragment))
	_sync_state()

func _node_added(node: Node) -> void:
	if node is MemoryFragment and is_instance_valid(memory) and memory.is_ancestor_of(node):
		refresh_fragments.call_deferred()

func _node_removed(node: Node) -> void:
	if node is MemoryFragment and _fragments.has(node): refresh_fragments.call_deferred()

func _fragment_state(state: MemoryFragment.State, fragment: MemoryFragment) -> void:
	if state == MemoryFragment.State.DECAYING:
		_finished[fragment.get_instance_id()] = true
		_sync_state()

func get_next_fragment() -> MemoryFragment:
	for fragment in _fragments:
		if not is_instance_valid(fragment) or not fragment.is_inside_tree(): continue
		if fragment.get_viewport()!=get_viewport() or not fragment.is_visible_in_tree() or not fragment.can_process(): continue
		if not _finished.get(fragment.get_instance_id(),false): return fragment
	return null

func _input_allowed() -> bool:
	return is_instance_valid(actor) and actor.is_inside_tree() and actor.can_process() and actor.is_physics_processing() \
		and is_instance_valid(input_gate) and input_gate.input_allowed()

func _physics_process(_delta: float) -> void:
	_sync_state()

func _sync_state() -> void:
	var next := get_next_fragment()
	if is_instance_valid(active_guide):
		if not is_instance_valid(active_destination) or active_destination!=next or not _input_allowed(): active_guide.stop()
		if not active_guide.is_playing():
			active_guide = null
			active_destination = null
	if is_instance_valid(button): button.available = is_instance_valid(next) and not is_instance_valid(active_guide)

func request_guidance() -> bool:
	_sync_state()
	if not _input_allowed() or is_instance_valid(active_guide) or not is_instance_valid(memory): return false
	var destination := get_next_fragment()
	if not is_instance_valid(destination): return false
	var definitions: Array[Node3D] = []
	var chosen: FragmentBrushstrokeGuide
	for node in memory.find_children("*","FragmentBrushstrokeGuide",true,false):
		var route := node as FragmentBrushstrokeGuide
		definitions.append(route)
		if route.end_anchor == destination: chosen = route
	# Snapshot at release. The moving actor is never assigned as a live start anchor.
	var points: PackedVector3Array = _planner.build(memory,actor,destination,definitions)
	if points.size()<2: return false
	if not chosen:
		if not is_instance_valid(_fallback):
			_fallback = GUIDE.instantiate() as FragmentBrushstrokeGuide
			_fallback.name = "RequestedBrushstroke"
			add_child(_fallback,false,Node.INTERNAL_MODE_BACK)
		chosen = _fallback
	chosen.play_route(points)
	if not _curve_is_clear(chosen):
		# Rounded handles must never cut a corner inside a fence or cabinet.
		chosen.play_route(points,false)
	active_guide = chosen
	active_destination = destination
	_sync_state()
	guidance_started.emit(destination)
	return true

func _curve_is_clear(guide: FragmentBrushstrokeGuide) -> bool:
	var previous := guide.to_global(guide.sample_path(0.0))
	var count := maxi(8,ceili(guide._route_length*guide.global_basis.get_scale().length()/sqrt(3.0)/0.18))
	for i in range(1,count+1):
		var point := guide.to_global(guide.sample_path(float(i)/count))
		if not _planner.segment_clear(previous,point): return false
		previous = point
	return true
