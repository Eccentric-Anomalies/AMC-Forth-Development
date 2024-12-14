using Godot;

// Forth STRING word set

namespace Forth.String
{
    [GlobalClass]
    public partial class StringSet : Godot.RefCounted
    {
        public Compare Compare;
        public CMove CMove;
        public CMoveUp CMoveUp;
        private const string Wordset = "STRING";

        public StringSet(AMCForth _forth)
        {
            Compare = new(_forth, Wordset);
            CMove = new(_forth, Wordset);
            CMoveUp = new(_forth, Wordset);
        }
    }
}
