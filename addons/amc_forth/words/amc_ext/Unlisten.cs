using Godot;

namespace Forth.AMCExt
{
[GlobalClass]
	public partial class Unlisten : Forth.Words
	{

		public Unlisten(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "UNLISTEN";
			Description = "Remove a lookup entry for the IO port p.";
			StackEffect = "( p - )";
		}

		public override void Call()
		{
			Forth.AMCExtWords.Listen.GetPortAddress();
			Forth.Push(0);
			Forth.CoreWords.Swap.Call();
			Forth.CoreWords.Store.Call();
		}
	}
}