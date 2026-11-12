extends Node
## Persistent two-player connection; scene navigation belongs to each player.
signal status_changed
signal presence_changed
signal snapshot_received(time: float, position: Vector3, heading: float, walking: bool)

enum State { OFFLINE, HOSTING, JOINING, GUEST }
enum MenuMode { HOST, JOIN }
const PORT := 24680
const SERVER_ID := 1
const PROTOCOL_VERSION := 4
const JOIN_TIMEOUT_MS := 10000

var state := State.OFFLINE
var menu_mode := MenuMode.HOST
var _main_menu_opened := false
var status := ""
var local_avatar := MemoryExplorer.Avatar.SOREN
var partner_avatar := MemoryExplorer.Avatar.SOREN
var partner_id := 0
var local_memory := ""
var partner_memory := ""
var local_visit := 0
var partner_visit := 0
var last_address := ""
var _peer: ENetMultiplayerPeer
var _join_deadline := 0

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	set_process(false)

func initialize_main_menu() -> void:
	# Auto-host only on the first title screen of this application run.
	# Returning to menus respects an existing connection or an explicit disconnect.
	if _main_menu_opened:
		return
	_main_menu_opened = true
	if state == State.OFFLINE:
		host(MemoryExplorer.preferred_avatar)
	elif state in [State.JOINING, State.GUEST]:
		menu_mode = MenuMode.JOIN

func host(avatar: MemoryExplorer.Avatar) -> bool:
	if state != State.OFFLINE:
		return false
	menu_mode = MenuMode.HOST
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 1)
	if error != OK:
		_set_status("Couldn’t host (%s)." % error_string(error))
		return false
	set_avatar(avatar)
	state = State.HOSTING
	_peer = peer
	multiplayer.multiplayer_peer = peer
	_set_status("Waiting for your partner")
	return true

func join(address: String, avatar: MemoryExplorer.Avatar) -> void:
	if state != State.OFFLINE:
		return
	menu_mode = MenuMode.JOIN
	address = address.strip_edges()
	if not address.is_valid_ip_address():
		_set_status("Enter the host’s IP address.")
		return
	last_address = address
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, PORT)
	if error != OK:
		_set_status("Couldn’t connect (%s)." % error_string(error))
		return
	set_avatar(avatar)
	state = State.JOINING
	_peer = peer
	multiplayer.multiplayer_peer = peer
	_join_deadline = Time.get_ticks_msec() + JOIN_TIMEOUT_MS
	set_process(true)
	_set_status("Connecting…")

func leave(message := "") -> void:
	state = State.OFFLINE
	_clear_partner()
	set_process(false)
	if _peer != null:
		_peer.close()
		multiplayer.multiplayer_peer = null
		_peer = null
	# A disconnect does not move the local player or change the current memory.
	_set_status(message)

func set_avatar(avatar: MemoryExplorer.Avatar) -> void:
	if not _valid_avatar(avatar):
		return
	local_avatar = avatar
	MemoryExplorer.preferred_avatar = avatar
	_advertise_presence()

func enter_memory(id: StringName) -> int:
	local_visit += 1
	local_memory = str(id)
	set_avatar(MemoryExplorer.preferred_avatar)
	presence_changed.emit()
	return local_visit

func exit_memory(id: StringName, visit: int) -> void:
	if local_memory != str(id) or local_visit != visit:
		return
	local_visit += 1
	local_memory = ""
	_advertise_presence()
	presence_changed.emit()

func shares_memory() -> bool:
	return partner_id != 0 and not local_memory.is_empty() and local_memory == partner_memory

func _advertise_presence() -> void:
	if partner_id != 0:
		_presence.rpc_id(partner_id, local_memory, local_visit, int(local_avatar))

func _clear_partner() -> void:
	partner_id = 0
	partner_memory = ""
	partner_visit = 0
	presence_changed.emit()

func _process(_delta: float) -> void:
	if state == State.JOINING and Time.get_ticks_msec() >= _join_deadline:
		leave("Couldn’t connect. Check the IP and Wi-Fi, then try again.")

func send_snapshot(position: Vector3, heading: float, walking: bool) -> void:
	if shares_memory():
		_receive_snapshot.rpc_id(partner_id, local_memory, local_visit, partner_visit,
			Time.get_ticks_usec() * 0.000001, position, heading, walking)

func _on_connected_to_server() -> void:
	if state == State.JOINING:
		_hello.rpc_id(SERVER_ID, PROTOCOL_VERSION, int(local_avatar), local_memory, local_visit)

func _on_connection_failed() -> void:
	if state == State.JOINING:
		leave("Couldn’t connect. Check the host’s IP and Wi-Fi.")

func _on_server_disconnected() -> void:
	if state == State.GUEST:
		leave("Host disconnected · Exploring solo")
	elif state == State.JOINING:
		leave("The host closed the connection.")

func _on_peer_disconnected(id: int) -> void:
	if state == State.HOSTING and id == partner_id:
		_clear_partner()
		_set_status("Waiting for your partner")

@rpc("any_peer", "reliable")
func _hello(version: int, avatar: int, memory: String, visit: int) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if state != State.HOSTING or partner_id != 0 or sender <= SERVER_ID:
		return
	if version != PROTOCOL_VERSION or not _valid_presence(memory, visit, avatar):
		_join_rejected.rpc_id(sender)
		return
	partner_id = sender
	partner_avatar = avatar as MemoryExplorer.Avatar
	partner_memory = memory
	partner_visit = visit
	_welcome.rpc_id(sender, int(local_avatar), local_memory, local_visit)
	presence_changed.emit()
	_set_status("Connected")

@rpc("authority", "reliable")
func _join_rejected() -> void:
	if state == State.JOINING:
		leave("This host is using an incompatible game version.")

@rpc("authority", "reliable")
func _welcome(avatar: int, memory: String, visit: int) -> void:
	if state != State.JOINING or not _valid_presence(memory, visit, avatar):
		return
	state = State.GUEST
	partner_id = SERVER_ID
	partner_avatar = avatar as MemoryExplorer.Avatar
	partner_memory = memory
	partner_visit = visit
	set_process(false)
	_advertise_presence()
	presence_changed.emit()
	_set_status("Connected")

@rpc("any_peer", "reliable")
func _presence(memory: String, visit: int, avatar: int) -> void:
	if partner_id == 0 or multiplayer.get_remote_sender_id() != partner_id or not _valid_presence(memory, visit, avatar):
		return
	if visit < partner_visit or (visit == partner_visit and memory != partner_memory):
		return
	partner_memory = memory
	partner_visit = visit
	partner_avatar = avatar as MemoryExplorer.Avatar
	presence_changed.emit()

@rpc("any_peer", "unreliable_ordered")
func _receive_snapshot(memory: String, source_visit: int, recipient_visit: int, time: float, position: Vector3, heading: float, walking: bool) -> void:
	if not shares_memory() or multiplayer.get_remote_sender_id() != partner_id:
		return
	if memory != local_memory or source_visit != partner_visit or recipient_visit != local_visit:
		return
	if not is_finite(time) or not position.is_finite() or not is_finite(heading):
		return
	snapshot_received.emit(time, position, heading, walking)

func _valid_presence(memory: String, visit: int, avatar: int) -> bool:
	return memory.length() <= 128 and visit >= 0 and _valid_avatar(avatar)

func _valid_avatar(avatar: int) -> bool:
	return avatar == MemoryExplorer.Avatar.SOREN or avatar == MemoryExplorer.Avatar.VIVIAN

func _set_status(message: String) -> void:
	status = message
	status_changed.emit()

func host_addresses() -> String:
	var ipv4 := PackedStringArray()
	for address in IP.get_local_addresses():
		if not address.contains(":") and not address.begins_with("127.") and not address.begins_with("169.254."):
			ipv4.append(address)
	return ", ".join(ipv4) if not ipv4.is_empty() else "Check your Wi-Fi IP"
