using Godot;

// Forth FILE word set

namespace Forth.File
{
    [GlobalClass]
    public partial class FileSet : Godot.RefCounted
    {
        public CloseFile CloseFile;
        public Included Included;
        public IncludeFile IncludeFile;
        public OpenFile OpenFile;
        public RO RO;
        public RW RW;
        public ReadLine ReadLine;
        public WO WO;
        private const string Wordset = "FILE";

        public FileSet(AMCForth _forth)
        {
            CloseFile = new(_forth, Wordset);
            Included = new(_forth, Wordset);
            IncludeFile = new(_forth, Wordset);
            OpenFile = new(_forth, Wordset);
            RO = new(_forth, Wordset);
            RW = new(_forth, Wordset);
            ReadLine = new(_forth, Wordset);
            WO = new(_forth, Wordset);
        }
    }
}
