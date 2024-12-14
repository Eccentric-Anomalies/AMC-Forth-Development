using System;
using Godot;

namespace Forth.Double
{
    [GlobalClass]
    public partial class DAbs : Forth.Words
    {
        public DAbs(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "DABS";
            Description = "Replace the top stack double item with its absolute value.";
            StackEffect = "( d - +d )";
        }

        public override void Call()
        {
            Forth.SetDint(0, Math.Abs(Forth.GetDint(0)));
        }
    }
}
