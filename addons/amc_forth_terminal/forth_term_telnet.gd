class_name ForthTermTelnet
## Telnet server Forth terminal
##

extends ForthTermBase

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
	1,  # don't echo
	255,
	251,
	1,  # will echo
	255,
	251,
	3,
	255,
	253,
	3
]

@export var listen_port: int = 23
@export var bind_address: String = "127.0.0.1"

var _connection: StreamPeerTCP = null
var _negotiation_complete := false
var _output_buffer := ""
var _server: TCPServer


## Poll the telnet _connection
func poll_connection() -> void:
	if not OS.has_feature("web"):  # no telnet in the browser
		if _server.is_listening():
			if _server.is_connection_available():
				_connection = _server.take_connection()
				_server.stop()  # do not listen now
				_connection.set_no_delay(true)
				forth.client_connected()
		elif _connection:  # not listening.. connected
			var connect_status = _connection.get_status()
			if (
				connect_status
				in [
					StreamPeerTCP.Status.STATUS_ERROR,
					StreamPeerTCP.Status.STATUS_NONE
				]
			):
				_connection.disconnect_from_host()
				_start_listening()
			elif connect_status == StreamPeerTCP.Status.STATUS_CONNECTING:
				print("connecting")
			elif connect_status == StreamPeerTCP.Status.STATUS_CONNECTED:
				# stuff waiting to go out?
				if _output_buffer.length():
					_connection.put_data(_output_buffer.to_ascii_buffer())
					_output_buffer = ""
				# stuff waiting to come in?
				var bytes_available: int = _connection.get_available_bytes()
				if bytes_available > 0:
					var raw_data = _connection.get_data(bytes_available)
					# crude check for telnet negotiation
					if raw_data[0] == 0 and raw_data[1][0] == 255:
						if not _negotiation_complete:
							# We ask for no terminal echo
							_connection.put_data(REQUIRED_FEATURES)
							# ignore further messages and hope for the best
							_negotiation_complete = true
					# just retrieve the text and pass to forth
					else:
						var instr: String = raw_data[1].get_string_from_ascii()
						if forth.is_ready_for_input():
							forth.terminal_in(instr)
						else:
							# discard any input while the forth UI is busy
							instr = ""


## Initialize (executed automatically by ForthTermTelnet.new())
##
func _init(_forth: AMCForth) -> void:
	if not OS.has_feature("web"):
		super(_forth)
		# now safe to receive output
		connect_forth_output()
		_server = TCPServer.new()
		_start_listening()


## Start listening for a telnet _connection
func _start_listening() -> void:
	var err: Error = _server.listen(listen_port, bind_address)
	if err != OK:
		printerr("Failed to listen on port ", listen_port)
	_connection = null
	_output_buffer = ""


func _on_forth_output(text: String) -> void:
	_output_buffer += text
