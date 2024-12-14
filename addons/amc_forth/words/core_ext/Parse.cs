using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class Parse : Forth.Words
    {
        public Parse(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "PARSE";
            Description =
                "Parse text to the first instance of char, returning the address "
                + "and length of a temporary location containing the parsed text. "
                + "Returns a counted string. Consumes the final delimiter.";
            StackEffect = "( char - c_addr n )";
        }

        public override void Call()
        {
            var count = 0;
            var ptr = AMCForth.WordBuffStart + 1;
            var delim = Forth.Pop();
            Forth.CoreWords.Source.Call();
            var source_size = Forth.Pop();
            var source_start = Forth.Pop();
            Forth.CoreWords.ToIn.Call();
            var ptraddr = Forth.Pop();
            Forth.Push(ptr);
            // parsed text begins here
            while (true)
            {
                var t = Forth.Ram.GetByte(source_start + Forth.Ram.GetInt(ptraddr));
                // increment the input pointer
                if (t != 0)
                {
                    Forth.Ram.SetInt(ptraddr, Forth.Ram.GetInt(ptraddr) + 1);
                }
                // a null character also stops the parse
                if (t != 0 && t != delim)
                {
                    Forth.Ram.SetByte(ptr, t);
                    ptr += 1;
                    count += 1;
                }
                else
                {
                    break;
                }
            }
            Forth.Push(count);
        }
    }
}
