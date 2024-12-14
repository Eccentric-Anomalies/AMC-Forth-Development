using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class SToD : Forth.Words
    {
        public SToD(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "S>D";
            Description = "Convert a single cell number n to its double equivalent d.";
            StackEffect = "( n - d )";
        }

        public override void Call()
        {
            Forth.PushDint(Forth.Pop());
        }
    }
}
