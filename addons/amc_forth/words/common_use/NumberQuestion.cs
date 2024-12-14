using Godot;

namespace Forth.CommonUse
{
    [GlobalClass]
    public partial class NumberQuestion : Forth.Words
    {
        public NumberQuestion(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "NUMBER?";
            Description =
                "Attempt to convert a string at c-addr of length u into digits using "
                + "BASE as radix. If a decimal point is found, return a double, otherwise "
                + "return a single, with a flag: 0 = failure, 1 = single, 2 = double.";
            StackEffect = "( c-addr u - 0 | n 1 | d 2 )";
        }

        public override void Call()
        {
            var radix = Forth.Ram.GetInt(AMCForth.Base);
            var len = Forth.Pop();
            // length of word
            var caddr = Forth.Pop();
            // start of word
            var t = Forth.Util.StrFromAddrN(caddr, len);
            if (t.Contains(".") && AMCForth.IsValidLong(t.Replace(".", ""), radix))
            {
                var t_strip = t.Replace(".", "");
                var temp = AMCForth.ToLong(t_strip, radix);
                Forth.PushDint(temp);
                Forth.Push(2);
            }
            else if (AMCForth.IsValidInt(t, radix))
            {
                var temp = AMCForth.ToInt(t, radix);

                // single-precision
                Forth.Push(temp);
                Forth.Push(1);
            }
            else // nothing we recognize
            {
                Forth.Push(0);
            }
        }
    }
}
