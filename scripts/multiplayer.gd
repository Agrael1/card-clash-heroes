extends Node2D

@onready var host_button : Button = $Host
@onready var join_button : Button = $Join

@export var port : int = 123
@export var address : String = "localhost"

var peer = ENetMultiplayerPeer.new()


func disable_buttons():
	host_button.disabled = true
	join_button.disabled = true
	host_button.visible = false
	join_button.visible = false


func _on_join_pressed() -> void:
	disable_buttons()
	
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer

func _on_host_pressed() -> void:
	disable_buttons()
	
	peer.create_server(port, 1)
	multiplayer.multiplayer_peer = peer
