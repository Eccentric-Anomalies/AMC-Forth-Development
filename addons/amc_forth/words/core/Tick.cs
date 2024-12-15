using System;
using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Tick : Forth.Words
    {
        public Tick(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "'";
            Description =
                "Search the dictionary for <name> and leave its execution token "
                + "on the stack. Abort if name cannot be found.";
            StackEffect = "( 'name' - xt )";
        }

        public override void Call()
        {
            // retrieve the name token
            Forth.CoreExtWords.ParseName.Call();
            var len = Forth.Pop(); // length
            var caddr = Forth.Pop(); // start
            var word = Forth.Util.StrFromAddrN(caddr, len);
            var token_addr_immediate = Forth.FindInDict(word); // look the name up
            if (token_addr_immediate.Addr != 0) // either in user dictionary, a built-in xt, or neither
            {
                Forth.Push(token_addr_immediate.Addr);
            }
            else
            {
                try
                {
                    Forth.Push(FromName(word).Xt);
                }
                catch (ArgumentOutOfRangeException e)
                {
                    Forth.Util.PrintUnknownWord(e.ParamName);
                }
            }
        }
    }
}
