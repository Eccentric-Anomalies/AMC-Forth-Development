using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class CFetch : Forth.Words
	{

		public CFetch(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "C@";
			Description = 
				"Replace c-addr with the contents of the character at c-addr. The character "+
				"fetched is stored in the low-order character of the top stack item, with "+
				"the remaining bits set to zero.";
			StackEffect = "( c-addr - c )";
		}

		public override void Call()
		{
			Forth.Push(Forth.Ram.GetByte(Forth.Pop()));
		}
	}
}