using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class PlusStore : Forth.Words
    {
        public PlusStore(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "+!";
            Description =
                "Add n to the contents of the cell at a-addr and store the result in the "
                + "cell at a-addr, removing both from the stack.";
            StackEffect = "( n a-addr - )";
        }

        public override void Call()
        {
            var addr = Forth.Pop();
            var a = Forth.Ram.GetInt(addr);
            Forth.Ram.SetInt(addr, a + Forth.Pop());
        }
    }
}
