class_name ForthRAM
## Definitions for working with "physical" RAM
##
## (1) Defines the size of a Forth cell and double-cell
## (2) Functions for setting and getting numbers in RAM

extends RefCounted

# cell size should be 2 or 4
# if 2, use (encode|decode)_(s|u)16 and (encode|decode)_(s_u)32
# if 4, use (encode|decode)_(s|u)32 and (encode|decode)_(s_u)64
const CELL_SIZE := 4
const DCELL_SIZE := CELL_SIZE * 2
const CELL_BITS := CELL_SIZE * 8
const DCELL_BITS := CELL_BITS * 2
const CELL_MAX := 2 ** CELL_BITS
const CELL_MSB_MASK := CELL_MAX >> 1
const CELL_MASK := CELL_MAX - 1
const CELL_MAX_POSITIVE = (2 ** (CELL_BITS - 1)) - 1
const CELL_MAX_NEGATIVE = -(CELL_MAX_POSITIVE + 1)

# buffer for all physical RAM
var _ram := PackedByteArray()

# forth ordering scratch
var _d_scratch := PackedByteArray()


# save ram state
func save_state(config:ConfigFile) -> void:
	config.set_value("ram", "image", _ram)

# restore ram state
func load_state(config:ConfigFile) -> void:
	_ram = config.get_value("ram", "image")


# allocate memory for RAM and a DCELL_SIZE scratchpad
func _init(size: int):
	_ram.resize(size)
	_d_scratch.resize(DCELL_SIZE)


# convert int to standard forth ordering and vice versa
func _d_swap(num: int) -> int:
	_d_scratch.encode_s64(0, num)
	var t: int = _d_scratch.decode_s32(0)
	_d_scratch.encode_s32(0, _d_scratch.decode_s32(CELL_SIZE))
	_d_scratch.encode_s32(CELL_SIZE, t)
	return _d_scratch.decode_s64(0)


# 32 to 64-bit conversions


# convert int to [hi, lo] 32-bit words
func split_64(val: int) -> Array:
	_d_scratch.encode_s64(0, val)
	return [_d_scratch.decode_s32(4), _d_scratch.decode_s32(0)]


# convert (hi, lo) to 64-bit int
func combine_64(hi: int, lo: int) -> int:
	_d_scratch.encode_s32(4, hi)
	_d_scratch.encode_s32(0, lo)
	return _d_scratch.decode_s64(0)


# return just the cell-sized low-order portion of 64-bit int
func truncate_to_cell(val: int) -> int:
	if val > CELL_MAX_POSITIVE or val < CELL_MAX_NEGATIVE:
		return split_64(val)[1]
	return val


# Data stack and RAM helpers
func set_byte(addr: int, val: int) -> void:
	_ram.encode_u8(addr, val)


func get_byte(addr: int) -> int:
	return _ram.decode_u8(addr)


# signed cell-sized values


func set_int(addr: int, val: int) -> void:
	_ram.encode_s32(addr, val)


func get_int(addr: int) -> int:
	return _ram.decode_s32(addr)


# unsigned cell-sized values


func set_word(addr: int, val: int) -> void:
	_ram.encode_u32(addr, val)


func get_word(addr: int) -> int:
	return _ram.decode_u32(addr)


# signed double-precision values


func set_dint(addr: int, val: int) -> void:
	_ram.encode_s64(addr, _d_swap(val))


func get_dint(addr: int) -> int:
	return _d_swap(_ram.decode_s64(addr))


# unsigned double-precision values


func set_dword(addr: int, val: int) -> void:
	_ram.encode_u64(addr, _d_swap(val))


func get_dword(addr: int) -> int:
	return _d_swap(_ram.decode_u64(addr))
