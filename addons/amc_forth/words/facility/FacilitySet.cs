using Godot;

// Forth FACILITY word set

namespace Forth.Facility
{
    [GlobalClass]
    public partial class FacilitySet : Godot.RefCounted
    {
        public AtXY AtXY;
        public Page Page;
        private const string Wordset = "FACILITY";

        public FacilitySet(AMCForth _forth)
        {
            AtXY = new(_forth, Wordset);
            Page = new(_forth, Wordset);
        }
    }
}
