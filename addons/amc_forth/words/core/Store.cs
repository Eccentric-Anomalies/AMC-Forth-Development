using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Store : Forth.Words
    {
        public Store(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "!";
            Description = "Store x in the cell at a-addr.";
            StackEffect = "( x a-addr - )";
        }

        public override void Call()
        {
            var addr = Forth.Pop();
            Forth.Ram.SetInt(addr, Forth.Pop());
        }
    }
}
