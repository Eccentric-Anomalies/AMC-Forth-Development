using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class In : Words
    {
        public In(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "IN";
            Description = "Return cell data x from memory at input port p.";
            StackEffect = "( p - x )";
        }

        public override void Call()
        {
            Forth.AMCExtWords.InAddr.Call(); // get port address
            Forth.CoreWords.Fetch.Call(); // get the data
        }
    }
}
