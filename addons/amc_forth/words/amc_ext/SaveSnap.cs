using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class SaveSnap : Forth.Words
    {
        public SaveSnap(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "SAVE-SNAP";
            Description = "Save the Forth system RAM to backup file.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.SaveSnapshot();
        }
    }
}
