using Godot;

namespace Forth.CommonUse
{
[GlobalClass]
	public partial class TwoPlus : Forth.Words
	{

		public TwoPlus(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "2+";
			Description = "Add two to n1, leaving n2.";
			StackEffect = "( n1 - n2 )";
		}

		public override void Call()
		{
			Forth.Push(2);
			Forth.CoreWords.Plus.Call();
		}
	}
}