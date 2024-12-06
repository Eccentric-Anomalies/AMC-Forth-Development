using Godot;
using Godot.Collections;

//# Define key codes for interacting with a terminal

//#


[GlobalClass]
public partial class ForthTerminal : Godot.RefCounted
{
	public const byte BSP = 0x08;
	public const byte CR = 0x0D;
	public const byte LF = 0x0A;
	public const string CRLF = "\r\n";
	public const char ESC = (char)0x1B;
	public const byte DEL_LEFT = 0x7F;
	public const byte BL = 0x20;
	public const string DEL = "\u001B[3~";
	public const string UP = "\u001B[A";
	public const string DOWN = "\u001B[B";
	public const string RIGHT = "\u001B[C";
	public const string LEFT = "\u001B[D";
	public const string CLRLINE = "\u001B[2K";
	public const string CLRSCR = "\u001B[2J";
	public const string PUSHXY = "\u001B7";
	public const string POPXY = "\u001B8";
	public const string MODESOFF = "\u001B[m";
	public const string BOLD = "\u001B[1m";
	public const string LOWINT = "\u001B[2m";
	public const string UNDERLINE = "\u001B[4m";
	public const string BLINK = "\u001B[5m";
	public const string REVERSE = "\u001B[7m";
	public const string INVISIBLE = "\u001B[8m";
	public const int COLUMNS = 80;
	public const int ROWS = 24;


}
