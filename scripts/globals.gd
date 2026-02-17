extends Node

# used to store 
var port
var is_server = false

func set_port(port_num:int):
	port = port_num
	
func get_port() -> int:
	return port
