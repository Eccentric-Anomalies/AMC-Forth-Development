using Godot;

// Forth TOOLS EXT word set

namespace Forth.ToolsExt
{
    [GlobalClass]
    public partial class ToolsExtSet : Godot.RefCounted
    {
        public Ahead Ahead;
        public CsPick CsPick;
        public CsRoll CsRoll;
        private const string Wordset = "TOOLS EXT";

        public ToolsExtSet(AMCForth _forth)
        {
            Ahead = new(_forth, Wordset);
            CsPick = new(_forth, Wordset);
            CsRoll = new(_forth, Wordset);
        }
    }
}
