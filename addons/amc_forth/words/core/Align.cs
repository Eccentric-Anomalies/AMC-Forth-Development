using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Align : Forth.Words
	{

		public Align(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "ALIGN";
			Description = "If the data-space pointer is not aligned, reserve space to align it.";
			StackEffect = "( - )";
		}

		public override void Call()
		{
			Forth.Push(Forth.DictTopP);
			Forth.CoreWords.Aligned.Call();
			Forth.DictTopP = Forth.Pop();

			// preserve dictionary state
			Forth.SaveDictTop();
		}
	}
}