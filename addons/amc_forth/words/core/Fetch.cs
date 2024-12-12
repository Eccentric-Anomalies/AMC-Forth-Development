using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Fetch : Forth.Words
	{

		public Fetch(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "@";
			Description = "Replace a-addr with the contents of the cell at a_addr.";
			StackEffect = "( a_addr - x )";
		}

		public override void Call()
		{
			Forth.Push(Forth.Ram.GetInt(Forth.Pop()));
		}
	}
}