class_name ForthTerminal
## Define key codes for interacting with a terminal
##

extends RefCounted

const BSP := char(0x08)
const CR := char(0x0D)
const LF := char(0x0A)
const CRLF := "\r\n"
const ESC := char(0x1B)
const DEL_LEFT := char(0x7F)
const BL := char(0x20)
const DEL := ESC + "[3~"
const UP := ESC + "[A"
const DOWN := ESC + "[B"
const RIGHT := ESC + "[C"
const LEFT := ESC + "[D"
const CLREOL := ESC + "[2K"
const COLUMNS := 80
const ROWS := 24
