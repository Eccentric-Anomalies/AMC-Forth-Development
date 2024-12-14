using Godot;

// Forth STRING word set

namespace Forth.Double
{
    [GlobalClass]
    public partial class DoubleSet : Godot.RefCounted
    {
        public DDot DDot;
        public DMinus DMinus;
        public DPlus DPlus;
        public DLessThan DLessThan;
        public DEquals DEquals;
        public DZeroLess DZeroLess;
        public DZeroEqual DZeroEqual;
        public DTwoStar DTwoStar;
        public DTwoSlash DTwoSlash;
        public DToS DToS;
        public DAbs DAbs;
        public DMax DMax;
        public DMin DMin;
        public DNegate DNegate;
        public MStarSlash MStarSlash;
        public MPlus MPlus;
        public TwoConstant TwoConstant;
        public TwoLiteral TwoLiteral;
        public TwoVariable TwoVariable;
        private const string Wordset = "DOUBLE";

        public DoubleSet(AMCForth _forth)
        {
            DDot = new(_forth, Wordset);
            DMinus = new(_forth, Wordset);
            DPlus = new(_forth, Wordset);
            DLessThan = new(_forth, Wordset);
            DEquals = new(_forth, Wordset);
            DZeroLess = new(_forth, Wordset);
            DZeroEqual = new(_forth, Wordset);
            DTwoStar = new(_forth, Wordset);
            DTwoSlash = new(_forth, Wordset);
            DToS = new(_forth, Wordset);
            DAbs = new(_forth, Wordset);
            DMax = new(_forth, Wordset);
            DMin = new(_forth, Wordset);
            DNegate = new(_forth, Wordset);
            MStarSlash = new(_forth, Wordset);
            MPlus = new(_forth, Wordset);
            TwoConstant = new(_forth, Wordset);
            TwoLiteral = new(_forth, Wordset);
            TwoVariable = new(_forth, Wordset);
        }
    }
}
