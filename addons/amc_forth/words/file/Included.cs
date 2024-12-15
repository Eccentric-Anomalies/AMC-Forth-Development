using Godot;

namespace Forth.File
{
    [GlobalClass]
    public partial class Included : Forth.Words
    {
        public Included(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "INCLUDED";
            Description =
                "Same as INCLUDE-FILE, except file is specified by its name, as a "
                + "caddr and length u. The file is opened and its fileid is stored in "
                + "SOURCE-ID.";
            StackEffect = "( i*x c-addr u - j*x )";
        }

        public override void Call()
        {
            Forth.FileWords.RO.Call();
            //# read only
            Forth.FileWords.OpenFile.Call();
            var ior = Forth.Pop();
            var fileid = Forth.Pop();
            if (ior != 0)
            {
                Forth.Util.RprintTerm(" File not found");
                return;
            }
            Forth.Push(fileid);
            Forth.FileWords.IncludeFile.Call();
        }
    }
}
