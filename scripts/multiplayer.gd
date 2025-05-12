extends Node

signal noray_connected
signal join_connected

const NORAY_ADDRESS = "tomfol.io"
const NORAY_PORT = 8890

var is_host = false
var external_oid = ""

func _ready():
	Noray.on_connect_to_host.connect(on_noray_connected)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)
	Noray.connect_to_host(NORAY_ADDRESS, NORAY_PORT)

func on_noray_connected():
	print("Connected to Noray server")
	
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	noray_connected.emit()

func host():
	print("Hosting")
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = peer
	is_host = true

func unhost():
	is_host = false
	multiplayer.multiplayer_peer = null

func join(oid : String):
	var parts = oid.split(":")
	if parts.size() == 2 and (parts[0].is_valid_ip_address() or parts[0].is_empty()):
		# LAN connect
		var ip : String = parts[0]
		var port : String = parts[1]
		var peer = ENetMultiplayerPeer.new()
		var result = peer.create_client(ip if !ip.is_empty() else "localhost", port.to_int())
		multiplayer.multiplayer_peer = peer
		return result == OK
		
	
	Noray.connect_nat(oid)
	external_oid = oid
	return true

func handle_nat_connection(address, port):
	var err = await connect_to_server(address, port)
	
	if err != OK && !is_host:
		print("NAT failed, using relay")
		Noray.connect_relay(external_oid)
		err = OK
	
	return err

func handle_relay_connection(address, port):
	return await connect_to_server(address, port)

func connect_to_server(address, port):
	var err = OK
	
	if !is_host:
		var udp = PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)
		
		err = await PacketHandshake.over_packet_peer(udp)
		udp.close()
		
		if err != OK:
			if err != ERR_BUSY:
				print("Handshake failed")
				return err
		else:
			print("Handshake success")
		
		var peer = ENetMultiplayerPeer.new()
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		
		if err != OK:
			return err
		
		multiplayer.multiplayer_peer = peer
		
		return OK
	else:
		err = await PacketHandshake.over_enet(multiplayer.multiplayer_peer.host, address, port)
	
	return err
