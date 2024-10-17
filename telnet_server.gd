extends Node2D

const REQUIRED_FEATURES = [
	255,
	251,
	31,
	255,
	251,
	32,
	255,
	251,
	24,
	255,
	251,
	39,
	255,
	254,
	1,   # don't echo
	255,
	251,
	1,   # will echo
	255,
	251,
	3,
	255,
	253,
	3
]

@export var listen_port: int = 23
@export var bind_address: String = "127.0.0.1"

var forth: AMCForth
var connection: StreamPeerTCP = null
var negotiation_complete := false
var output_buffer := ""

@onready var server: TCPServer = TCPServer.new()


func _ready() -> void:
	_start_listening()
	forth = AMCForth.new()
	forth.connect("terminal_out", _on_forth_output)
	forth.init()


func _process(_delta: float) -> void:
	if server.is_listening():
		if server.is_connection_available():
			connection = server.take_connection()
			server.stop()  # do not listen now
			connection.set_no_delay(true)
	else:  # not listening.. connected
		if connection:
			var connect_status = connection.get_status()
			if connect_status == StreamPeerTCP.Status.STATUS_ERROR:
				connection.disconnect_from_host()
				_start_listening()
			elif connect_status == StreamPeerTCP.Status.STATUS_CONNECTED:
				# stuff waiting to go out?
				if output_buffer.length():
					connection.put_data(output_buffer.to_ascii_buffer())
					output_buffer = ""
				# stuff waiting to come in?
				var bytes_available: int = connection.get_available_bytes()
				if bytes_available > 0:
					var raw_data = connection.get_data(bytes_available)
					# crude check for telnet negotiation
					if raw_data[0] == 0 and raw_data[1][0] == 255:
						if not negotiation_complete:
							# We ask for no terminal echo
							connection.put_data(REQUIRED_FEATURES)
							# ignore further messages and hope for the best
							negotiation_complete = true
					# just retrieve the text and pass to forth
					else:
						var instr: String = raw_data[1].get_string_from_ascii()
						forth.terminal_in(instr)


func _start_listening() -> void:
	var err: Error = server.listen(listen_port, bind_address)
	if err != OK:
		printerr("Failed to listen on port ", listen_port)
	connection = null
	output_buffer = ""


func _on_forth_output(text: String) -> void:
	output_buffer += text
