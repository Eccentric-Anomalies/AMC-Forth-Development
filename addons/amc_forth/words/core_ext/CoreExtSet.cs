using System.Windows.Markup;
using Godot;

// Forth CORE EXT word set

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class CoreExtSet : Godot.RefCounted
    {
        public DotLeftParenthesis DotLeftParenthesis;
        public BackSlash BackSlash;
        public NotEqual NotEqual;
        public ZeroNotEqual ZeroNotEqual;
        public ZeroGreaterThan ZeroGreaterThan;
        public TwoToR TwoToR;
        public TwoRFrom TwoRFrom;
        public TwoRFetch TwoRFetch;
        public Again Again;
        public BufferColon BufferColon;
        public CQuote CQuote;
        public False False;
        public Hex Hex;
        public Marker Marker;
        public Nip Nip;
        public Parse Parse;
        public ParseName ParseName;
        public Pick Pick;
        public SourceId SourceId;
        public To To;
        public True True;
        public Tuck Tuck;
        public ULessThan ULessThan;
        public Unused Unused;
        public Value Value;
        private const string Wordset = "CORE EXT";

        public CoreExtSet(AMCForth _forth)
        {
            DotLeftParenthesis = new(_forth, Wordset);
            BackSlash = new(_forth, Wordset);
            NotEqual = new(_forth, Wordset);
            ZeroNotEqual = new(_forth, Wordset);
            ZeroGreaterThan = new(_forth, Wordset);
            TwoToR = new(_forth, Wordset);
            TwoRFrom = new(_forth, Wordset);
            TwoRFetch = new(_forth, Wordset);
            Again = new(_forth, Wordset);
            BufferColon = new(_forth, Wordset);
            CQuote = new(_forth, Wordset);
            False = new(_forth, Wordset);
            Hex = new(_forth, Wordset);
            Marker = new(_forth, Wordset);
            Nip = new(_forth, Wordset);
            Parse = new(_forth, Wordset);
            ParseName = new(_forth, Wordset);
            Pick = new(_forth, Wordset);
            SourceId = new(_forth, Wordset);
            To = new(_forth, Wordset);
            True = new(_forth, Wordset);
            Tuck = new(_forth, Wordset);
            ULessThan = new(_forth, Wordset);
            Unused = new(_forth, Wordset);
            Value = new(_forth, Wordset);
        }
    }
}
