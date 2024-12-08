using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class ParseName : Forth.Words
	{

		public ParseName(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "PARSE-NAME";
			Description = "If the data-space pointer is not aligned, reserve space to align it.";
			StackEffect = "( - )";
		}

		public override void Call()
		{
			Forth.Push(ForthTerminal.BL.ToAsciiBuffer()[0]);
			Forth.FCore.Word.Call();
			Forth.FCore.Count.Call();
		}
	}
}