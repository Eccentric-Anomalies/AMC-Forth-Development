using Godot;

// Define key codes for interacting with a terminal

namespace Forth
{
    [GlobalClass]
    public partial class Terminal : Godot.GodotObject
    {
        public const string BSP = "\u0008";
        public const string CR = "\u000D";
        public const string LF = "\u000A";
        public const string CRLF = "\r\n";
        public const string ESC = "\u001B";
        public static string DEL_LEFT = "\u007F";
        public const string BL = " ";
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
}
