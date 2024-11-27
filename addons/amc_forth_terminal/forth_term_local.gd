class_name ForthTermLocal
## Local Forth terminal
##

extends ForthTermBase

const US_KEY_MAP: Dictionary = {
	"QuoteLeft": "`",
	"1": "1",
	"2": "2",
	"3": "3",
	"4": "4",
	"5": "5",
	"6": "6",
	"7": "7",
	"8": "8",
	"9": "9",
	"0": "0",
	"Minus": "-",
	"Equal": "=",
	"Backspace": ForthTerminal.DEL_LEFT,
	"Delete": ForthTerminal.DEL,
	"Tab": "\t",
	"BracketLeft": "[",
	"BracketRight": "]",
	"BackSlash": "\\",
	"Semicolon": ";",
	"Apostrophe": "'",
	"Enter": ForthTerminal.CRLF,
	"Comma": ",",
	"Period": ".",
	"Slash": "/",
	"Shift+QuoteLeft": "~",
	"Shift+1": "!",
	"Shift+2": "@",
	"Shift+3": "#",
	"Shift+4": "$",
	"Shift+5": "%",
	"Shift+6": "^",
	"Shift+7": "&",
	"Shift+8": "*",
	"Shift+9": "(",
	"Shift+0": ")",
	"Shift+Minus": "_",
	"Shift+Equal": "+",
	"Shift+Backspace": "\b",
	"Shift+Tab": "\t",
	"Shift+BracketLeft": "{",
	"Shift+BracketRight": "}",
	"Shift+BackSlash": "|",
	"Shift+Semicolon": ":",
	"Shift+Apostrophe": '"',
	"Shift+Enter": ForthTerminal.CRLF,
	"Shift+Comma": "<",
	"Shift+Period": ">",
	"Shift+Slash": "?",
	"Shift+AsciiTilde": "~",
	"Shift+Exclam": "!",
	"Shift+At": "@",
	"Shift+NumberSign": "#",
	"Shift+Dollar": "$",
	"Shift+Percent": "%",
	"Shift+AsciiCircum": "^",
	"Shift+Ampersand": "&",
	"Shift+Asterisk": "*",
	"Shift+ParenLeft": "(",
	"Shift+ParenRight": ")",
	"Shift+UnderScore": "_",
	"Shift+Plus": "+",
	"Shift+BraceLeft": "{",
	"Shift+BraceRight": "}",
	"Shift+Bar": "|",
	"Shift+Colon": ":",
	"Shift+QuoteDbl": '"',
	"Shift+Less": "<",
	"Shift+Greater": ">",
	"Shift+Question": "?",
	"A": "a",
	"B": "b",
	"C": "c",
	"D": "d",
	"E": "e",
	"F": "f",
	"G": "g",
	"H": "h",
	"I": "i",
	"J": "j",
	"K": "k",
	"L": "l",
	"M": "m",
	"N": "n",
	"O": "o",
	"P": "p",
	"Q": "q",
	"R": "r",
	"S": "s",
	"T": "t",
	"U": "u",
	"V": "v",
	"W": "w",
	"X": "x",
	"Y": "y",
	"Z": "z",
	"Space": " ",
	"Shift+A": "A",
	"Shift+B": "B",
	"Shift+C": "C",
	"Shift+D": "D",
	"Shift+E": "E",
	"Shift+F": "F",
	"Shift+G": "G",
	"Shift+H": "H",
	"Shift+I": "I",
	"Shift+J": "J",
	"Shift+K": "K",
	"Shift+L": "L",
	"Shift+M": "M",
	"Shift+N": "N",
	"Shift+O": "O",
	"Shift+P": "P",
	"Shift+Q": "Q",
	"Shift+R": "R",
	"Shift+S": "S",
	"Shift+T": "T",
	"Shift+U": "U",
	"Shift+V": "V",
	"Shift+W": "W",
	"Shift+X": "X",
	"Shift+Y": "Y",
	"Shift+Z": "Z",
	"Up": ForthTerminal.UP,
	"Down": ForthTerminal.DOWN,
	"Right": ForthTerminal.RIGHT,
	"Left": ForthTerminal.LEFT,
}

# bitmasks for different display modes in the terminal
# (must match definitions in shader)
const BOLD := 0x0100
const LOWINTENSITY := 0x0200
const UNDERLINE := 0x0400
const BLINK := 0x0800
const REVERSE := 0x1000
const INVISIBLE := 0x2000
const ASCII_MASK := 0x007f

const CURSOR_PERIOD_MSEC := 1000

var _screen_ram: PackedInt32Array

var _col: int
var _row: int
var _cursor: Vector2i = Vector2i(1, 1)
var _save_cursor: Vector2i = Vector2i(1, 1)
var _mode: int = 0
var _save_mode: int = 0
var _screen_material: ShaderMaterial
var _last_msec: int = 0
var _cursor_state: bool = false
var _blink_state: bool = false

# Special characters and combos
var _sp_chars: Dictionary = {
	ForthTerminal.BSP: _do_bsp,
	ForthTerminal.CR: _do_cr,
	ForthTerminal.LF: _do_lf,
	ForthTerminal.DEL_LEFT: _do_del_left,
	ForthTerminal.DEL: _do_del,
	ForthTerminal.UP: _do_up,
	ForthTerminal.DOWN: _do_down,
	ForthTerminal.RIGHT: _do_right,
	ForthTerminal.LEFT: _do_left,
	ForthTerminal.CLRLINE: _do_clrline,
	ForthTerminal.CLRSCR: _do_clrscr,
	ForthTerminal.PUSHXY: _do_pushxy,
	ForthTerminal.POPXY: _do_popxy,
	ForthTerminal.ESC: _do_esc,
	ForthTerminal.MODESOFF: _do_modesoff,
	ForthTerminal.BOLD: _do_bold,
	ForthTerminal.LOWINT: _do_lowint,
	ForthTerminal.UNDERLINE: _do_underline,
	ForthTerminal.BLINK: _do_blink,
	ForthTerminal.REVERSE: _do_reverse,
	ForthTerminal.INVISIBLE: _do_invisible,
}

# a list of keys, sorted in reverse order by length
var _sp_chars_keys: Array = []

var _blank = ForthTerminal.BL.to_ascii_buffer()[0]


## Initialize (executed automatically by ForthTermLocal.new())
##
func _init(_forth: AMCForth, screen_material: ShaderMaterial) -> void:
	super(_forth)
	# shader setup
	_screen_ram = PackedInt32Array()
	_screen_ram.resize(SCREEN_WIDTH * SCREEN_HEIGHT)
	_screen_material = screen_material
	_screen_material.set_shader_parameter("cols", SCREEN_WIDTH)
	_screen_material.set_shader_parameter("rows", SCREEN_HEIGHT)
	_screen_material.set_shader_parameter("display_power", true)
	set_power(true)  # Turn on the display!
	_set_screen_contents()
	_go_home()
	_last_msec = Time.get_ticks_msec()
	_last_msec -= _last_msec % (CURSOR_PERIOD_MSEC / 2)  # round to half a cursor cycle
	# Sort the special characters list
	_sp_chars_keys = _sp_chars.keys()
	_sp_chars_keys.sort_custom(_key_sort_func)
	# now safe to receive output
	connect_forth_output()
	forth.client_connected()


func set_power(state: bool) -> void:
	_screen_material.set_shader_parameter("display_power", state)


# custom function for sorting special characters by length
func _key_sort_func(x, y) -> bool:
	return x.length() > y.length()


# Receive local key events from the owning node
func handle_key_event(evt: InputEvent) -> void:
	var keycode: String = OS.get_keycode_string(
		evt.get_key_label_with_modifiers()
	)
	if (
		keycode in US_KEY_MAP
		and forth.is_ready_for_input()
		and evt.is_pressed()
	):
		forth.terminal_in(US_KEY_MAP[keycode])


# Called from owner _process
func update_time() -> void:
	var msec = Time.get_ticks_msec()
	if (msec < _last_msec) or (msec - _last_msec > CURSOR_PERIOD_MSEC / 2):
		# step _last_msec back to nearest half period
		_last_msec += (CURSOR_PERIOD_MSEC / 2)
		_cursor_state = not _cursor_state
		_screen_material.set_shader_parameter("cursor_state", _cursor_state)
		if _cursor_state:
			_blink_state = not _blink_state
			_screen_material.set_shader_parameter("blink_state", _blink_state)


# The forth output handler should be overridden in child classes
func _on_forth_output(_text: String) -> void:
	var text = _text
	while text.length():
		# look for a special character(s)
		var sp_found: bool = false
		for sch in _sp_chars_keys:  # look for longest special chars first!
			if text.find(sch) == 0:
				# do the thing
				_sp_chars[sch].call()
				# remove the special character(s)
				text = text.substr(sch.length())
				sp_found = true
				break
		# if no special character, display one character
		if not sp_found:
			_char_at_cursor(text[0].to_ascii_buffer()[0])
			_advance_cursor()
			text = text.substr(1)


# Transfer cursor position to the shader
func _set_screen_cursor() -> void:
	_screen_material.set_shader_parameter("cursor_position", _cursor)


# Transfer screen buffer to the shader
func _set_screen_contents() -> void:
	_screen_material.set_shader_parameter("ram", _screen_ram)


# Display character at cursor, moving cursor
func _char_at_cursor(ch: int) -> void:
	_screen_ram[(_cursor.x - 1) + (_cursor.y - 1) * SCREEN_WIDTH] = ch + _mode
	_set_screen_contents()


# Advance cursor
func _advance_cursor() -> void:
	_cursor.x += 1
	if _cursor.x > SCREEN_WIDTH:
		_cursor.x = 1
		_cursor.y += 1
		if _cursor.y > SCREEN_HEIGHT:
			_cursor.y = SCREEN_HEIGHT
			_line_feed()
	_set_screen_cursor()


func _line_feed() -> void:
	_screen_ram = _screen_ram.slice(SCREEN_WIDTH)
	_screen_ram.append_array(blank_line)
	_set_screen_contents()
	_set_screen_cursor()


# Set cursor to home
func _go_home() -> void:
	_cursor.x = 1
	_cursor.y = 1
	_set_screen_cursor()


func _do_bsp() -> void:  # is this different from left cursor?
	if _cursor.x > 1:
		_cursor.x -= 1
		_set_screen_cursor()


func _do_cr() -> void:
	_cursor.x = 1
	_set_screen_cursor()


func _do_lf() -> void:
	if _cursor.y < SCREEN_HEIGHT:
		_cursor.y += 1
		_set_screen_cursor()
	else:
		_line_feed()


func _do_esc() -> void:
	_char_at_cursor(1)  # display a diamond
	_advance_cursor()


func _do_del_left() -> void:
	_do_left()
	_char_at_cursor(0)


func _do_del() -> void:
	_char_at_cursor(0)


func _do_up() -> void:
	if _cursor.y > 1:
		_cursor.y -= 1
		_set_screen_cursor()


func _do_down() -> void:
	if _cursor.y < SCREEN_HEIGHT:
		_cursor.y += 1
		_set_screen_cursor()


func _do_right() -> void:
	if _cursor.x < SCREEN_WIDTH:
		_cursor.x += 1
		_set_screen_cursor()


func _do_left() -> void:
	if _cursor.x > 1:
		_cursor.x -= 1
		_set_screen_cursor()


func _do_clrline() -> void:
	var x = (_cursor.y - 1) * SCREEN_WIDTH
	for i in SCREEN_WIDTH:
		_screen_ram[x + i] = _blank
	_set_screen_contents()


func _do_clrscr() -> void:
	_screen_ram.fill(_blank)
	_go_home()
	_set_screen_contents()


func _do_pushxy() -> void:
	_save_cursor = _cursor
	_save_mode = _mode


func _do_popxy() -> void:
	_cursor = _save_cursor
	_mode = _save_mode
	_set_screen_cursor()


# Display modes


func _do_modesoff() -> void:
	_mode = 0


func _do_bold() -> void:
	_mode |= BOLD
	_mode &= ~LOWINTENSITY


func _do_lowint() -> void:
	_mode |= LOWINTENSITY
	_mode &= ~BOLD


func _do_underline() -> void:
	_mode |= UNDERLINE


func _do_blink() -> void:
	_mode |= BLINK


func _do_reverse() -> void:
	_mode |= REVERSE


func _do_invisible() -> void:
	_mode |= INVISIBLE
