using System;
using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class HelpWS : Forth.Words
    {
        public HelpWS(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "HELPWS";
            Description = "Display word set for the following Forth word.";
            StackEffect = "( 'name' - )";
        }

        public override void Call()
        {
            try
            {
                Forth.Util.PrintTerm(" " + FromName(Forth.AMCExtWords.Help.NextWord()).WordSet);
            }
            catch (ArgumentOutOfRangeException e)
            {
                Forth.Util.PrintUnknownWord(e.ParamName);
            }
        }
    }
}
