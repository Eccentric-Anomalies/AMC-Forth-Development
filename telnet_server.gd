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

var forth: AMCForth
var connection: StreamPeerTCP = null
var negotiation_complete := false
var output_buffer := ""  # output from pForth
var input_buffer := ""  # input to pForth

# pForth
var _pipe
var _thread
var _info

@onready var server: TCPServer = TCPServer.new()


func _ready() -> void:
	_start_listening()
	#forth = AMCForth.new()
	#forth.connect("terminal_out", _on_forth_output)
	# Tap into pForth
	_info = OS.execute_with_pipe("pforth.exe", PackedStringArray([]))
	if _info.size():
		print("pforth.exe running")
		_pipe = _info["stdio"]
		_thread = Thread.new()
		_thread.start(_thread_func)
		get_window().close_requested.connect(clean_func)


func _process(_delta: float) -> void:
	if server.is_listening():
		if server.is_connection_available():
			connection = server.take_connection()
			server.stop()  # do not listen now
			connection.set_no_delay(true)
			#forth.client_connected()
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
						var ascii: PackedByteArray = instr.to_ascii_buffer()
						input_buffer += ascii.get_string_from_ascii()
						_on_forth_input.call_deferred(input_buffer)


func _start_listening() -> void:
	var err: Error = server.listen(listen_port, bind_address)
	if err != OK:
		printerr("Failed to listen on port ", listen_port)
	connection = null
	output_buffer = ""


func _on_forth_output(text: String) -> void:
	for c in text.to_ascii_buffer():
		if c == 10:
			output_buffer += char(13)  # add a cr to the LF
		output_buffer += char(c)


func _on_forth_input(text: String) -> void:
	var buffer = text.to_utf8_buffer()
	_pipe.seek_end()
	#print("Error: ", _pipe.get_error())
	_pipe.store_buffer(buffer)
	#_pipe.store_line(text)
	#print("Error: ", _pipe.get_error())
	# print("file position: ", _pipe.get_position())  # FIXME always zero
	#print("Error: ", _pipe.get_error())
	print("sending to pipe: ", text)
	for c in buffer:
		print(c)
	input_buffer = ""


func _thread_func():
	while _pipe.is_open() and _pipe.get_error() == OK:
		_on_forth_output.call_deferred(char(_pipe.get_8()))
		if not input_buffer.is_empty():
			_on_forth_input.call_deferred(input_buffer)
	printerr("pipe is broken")


func clean_func():
	_pipe.close()
	_thread.wait_to_finish()
