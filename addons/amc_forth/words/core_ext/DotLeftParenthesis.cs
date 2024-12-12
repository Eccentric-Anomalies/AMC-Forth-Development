using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class DotLeftParenthesis : Forth.Words
	{

		public DotLeftParenthesis(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = ".(";
			Description = 
				"Begin parsing a comment, terminated by ')'. Comment text "+
				"will emit to the terminal when it is compiled.";
			StackEffect = "( - )";
		}

		public override void Call()
		{
			Forth.Push(")".ToAsciiBuffer()[0]);
			Forth.CoreExtWords.Parse.Call();
			Forth.CoreWords.Type.Call();
		}
	}
}