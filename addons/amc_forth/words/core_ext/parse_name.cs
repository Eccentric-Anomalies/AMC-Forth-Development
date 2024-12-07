using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class ParseName : Forth.WordBase
	{

		public ParseName(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "PARSE-NAME";
			Description = "If the data-space pointer is not aligned, reserve space to align it.";
			StackEffect = "( - )";
		}

		public override void Execute()
		{
			Forth.Push(ForthTerminal.BL.ToAsciiBuffer()[0]);
			Forth.FCore.Word.Execute();
			Forth.FCore.Count.Execute();
		}
	}
}