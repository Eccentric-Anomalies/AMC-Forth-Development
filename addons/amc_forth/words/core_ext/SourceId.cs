using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class SourceId : Forth.Words
	{

		public SourceId(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "SOURCE-ID";
			Description = 
				"Return a value indicating current input source. "+
				"Value is 0 for default user input, -1 for character string.";
			StackEffect = "( - n )";
		}

		public override void Call()
		{
			Forth.Push(Forth.SourceId);
		}
	}
}