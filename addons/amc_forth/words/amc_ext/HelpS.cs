using Godot;

namespace Forth.AMCExt
{
[GlobalClass]
	public partial class HelpS : Forth.Words
	{

		public HelpS(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "HELPS";
			Description = "Display stack definition for the following Forth word.";
			StackEffect = "( 'name' - )";
		}

		public override void Call()
		{
			Forth.Util.PrintTerm(" " + FromName(Forth.AMCExtWords.Help.NextWord()).StackEffect);
		}
	}
}