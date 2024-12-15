using Godot;

// Forth FILE EXT word set

namespace Forth.FileExt
{
    [GlobalClass]
    public partial class FileExtSet : Godot.RefCounted
    {
        public Include Include;
        private const string Wordset = "FILE EXT";

        public FileExtSet(AMCForth _forth)
        {
            Include = new(_forth, Wordset);
        }
    }
}
