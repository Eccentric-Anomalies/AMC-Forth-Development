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
const CLRLINE := ESC + "[2K"
const CLRSCR := ESC + "[2J"
const PUSHXY := ESC + "7"
const POPXY := ESC + "8"
const MODESOFF := ESC + "[m"
const BOLD := ESC + "[1m"
const LOWINT := ESC + "[2m"
const UNDERLINE := ESC + "[4m"
const BLINK := ESC + "[5m"
const REVERSE := ESC + "[7m"
const INVISIBLE := ESC + "[8m"
const COLUMNS := 80
const ROWS := 24
