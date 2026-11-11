extends Node
## One host and one guest. This node keeps a stable RPC path across scene changes.

signal status_changed
signal join_accepted(memory_index: int)
signal snapshot_received(time: float, position: Vector3, heading: float, walking: bool)

enum State { OFFLINE, HOSTING, JOINING, GUEST }
const PORT := 24680
const SERVER_ID := 1
# Memory indices now identify First Meeting and Seasonal Demo. Reject older catalogs.
const PROTOCOL_VERSION := 2
const JOIN_TIMEOUT_MS := 10000

var state := State.OFFLINE
var status := ""
var memory_index := -1
var local_avatar := MemoryExplorer.Avatar.SOREN
var partner_avatar := MemoryExplorer.Avatar.SOREN
var partner_id := 0
var last_address := ""
var _peer: ENetMultiplayerPeer
var _join_deadline := 0

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	set_process(false)

func host(index: int, avatar: MemoryExplorer.Avatar) -> bool:
	if state != State.OFFLINE:
		return false
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 1)
	if error != OK:
		_set_status("Couldn’t host on UDP port %d (%s)." % [PORT, error_string(error)])
		return false
	memory_index = index
	local_avatar = avatar
	state = State.HOSTING
	_peer = peer
	multiplayer.multiplayer_peer = peer
	_set_status("Waiting for your partner · %s" % _host_addresses())
	return true

func join(address: String, avatar: MemoryExplorer.Avatar) -> void:
	if state != State.OFFLINE:
		return
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
	local_avatar = avatar
	state = State.JOINING
	_peer = peer
	multiplayer.multiplayer_peer = peer
	_join_deadline = Time.get_ticks_msec() + JOIN_TIMEOUT_MS
	set_process(true)
	_set_status("Connecting to %s…" % address)

func leave(message := "") -> void:
	state = State.OFFLINE
	partner_id = 0
	memory_index = -1
	set_process(false)
	if _peer != null:
		_peer.close()
		multiplayer.multiplayer_peer = null
		_peer = null
	_set_status(message)

func _process(_delta: float) -> void:
	if state == State.JOINING and Time.get_ticks_msec() >= _join_deadline:
		leave("Connection timed out. Check the IP and Wi-Fi, or ask the host if the session is full.")

func send_snapshot(position: Vector3, heading: float, walking: bool) -> void:
	if partner_id != 0:
		_receive_snapshot.rpc_id(partner_id, Time.get_ticks_usec() * 0.000001, position, heading, walking)

func _on_connected_to_server() -> void:
	if state == State.JOINING:
		_hello.rpc_id(SERVER_ID, PROTOCOL_VERSION, int(local_avatar))

func _on_connection_failed() -> void:
	if state == State.JOINING:
		leave("Couldn’t connect. Check the host’s IP and Wi-Fi.")

func _on_server_disconnected() -> void:
	if state == State.GUEST:
		leave("Host left · Exploring solo")
	elif state == State.JOINING:
		leave("The host closed the connection.")

func _on_peer_disconnected(id: int) -> void:
	if state == State.HOSTING and id == partner_id:
		partner_id = 0
		_set_status("Partner left · %s" % _host_addresses())

@rpc("any_peer", "reliable")
func _hello(version: int, avatar: int) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if state != State.HOSTING or partner_id != 0 or sender <= SERVER_ID:
		return
	if version != PROTOCOL_VERSION or not _valid_avatar(avatar):
		_join_rejected.rpc_id(sender)
		return
	partner_id = sender
	partner_avatar = avatar as MemoryExplorer.Avatar
	_welcome.rpc_id(sender, memory_index, int(local_avatar))
	_set_status("Partner connected")

@rpc("authority", "reliable")
func _join_rejected() -> void:
	if state == State.JOINING:
		leave("This host is using an incompatible game version.")

@rpc("authority", "reliable")
func _welcome(index: int, avatar: int) -> void:
	if state != State.JOINING or index < 0 or not _valid_avatar(avatar):
		return
	state = State.GUEST
	partner_id = SERVER_ID
	partner_avatar = avatar as MemoryExplorer.Avatar
	memory_index = index
	set_process(false)
	_set_status("Joined host")
	join_accepted.emit(index)

@rpc("any_peer", "unreliable_ordered")
func _receive_snapshot(time: float, position: Vector3, heading: float, walking: bool) -> void:
	# Only the accepted partner can supply poses, and only for their own replica.
	if partner_id == 0 or multiplayer.get_remote_sender_id() != partner_id:
		return
	if not is_finite(time) or not position.is_finite() or not is_finite(heading):
		return
	snapshot_received.emit(time, position, heading, walking)

func _valid_avatar(avatar: int) -> bool:
	return avatar == MemoryExplorer.Avatar.SOREN or avatar == MemoryExplorer.Avatar.VIVIAN

func _set_status(message: String) -> void:
	status = message
	status_changed.emit()

func _host_addresses() -> String:
	var ipv4 := PackedStringArray()
	for address in IP.get_local_addresses():
		if not address.contains(":") and not address.begins_with("127.") and not address.begins_with("169.254."):
			ipv4.append(address)
	return "Host IP: %s" % ", ".join(ipv4) if not ipv4.is_empty() else "Check your device’s Wi-Fi IP"
