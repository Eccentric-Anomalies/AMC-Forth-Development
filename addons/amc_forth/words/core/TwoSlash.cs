using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class TwoSlash : Forth.Words
    {
        public TwoSlash(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "2/";
            Description =
                "Return x2, result of shifting x1 one bit towards LSB, "
                + "leaving the MSB unchanged.";
            StackEffect = "( x1 - x2 )";
        }

        public override void Call()
        {
            // shift right, copying MSB
            Forth.DataStack[Forth.DsP] = Forth.DataStack[Forth.DsP] >> 1;
        }
    }
}
