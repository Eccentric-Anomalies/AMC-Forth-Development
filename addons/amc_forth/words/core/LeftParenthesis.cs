using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class LeftParenthesis : Forth.Words
	{

		public LeftParenthesis(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "(";
			Description = "Begin parsing a comment, terminated by ')' character.";
			StackEffect = "( - )";
			Immediate = true;
		}

		public override void Call()
		{
			Forth.Push(")".ToAsciiBuffer()[0]);
			Forth.CoreExtWords.Parse.Call();
			Forth.CoreWords.TwoDrop.Call();
		}
	}
}