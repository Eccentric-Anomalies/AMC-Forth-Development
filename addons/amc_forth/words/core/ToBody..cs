using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class ToBody : Forth.Words
	{

		public ToBody(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = ">BODY";
			Description = 
				"Given a word's execution token, return the address of the start "+
				"of that word's parameter field.";
			StackEffect = "( xt - a-addr )";
		}

		public override void Call()
		{
			// Note this has no meaning for built-in execution tokens, which
			// have no parameter field.
			var xt = Forth.Pop();
			if(xt >= AMCForth.DictStart && xt < AMCForth.DictTop)
			{
				Forth.Push(xt + ForthRAM.CellSize);
			}
			else
			{
				Forth.Util.RprintTerm(" Invalid execution token (>BODY)");
			}
		}
	}
}