using Godot;

// Forth DOUBLE EXT word set

namespace Forth.DoubleExt
{
    [GlobalClass]
    public partial class DoubleExtSet : Godot.RefCounted
    {
        public TwoRot TwoRot;
        private const string Wordset = "DOUBLE EXT";

        public DoubleExtSet(AMCForth _forth)
        {
            TwoRot = new(_forth, Wordset);
        }
    }
}
