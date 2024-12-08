using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Count : Forth.Words
	{

		public Count(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "COUNT";
			Description = "Return the length u, and address of the text portion of a counted string.";
			StackEffect = "( c_addr1 - c_addr2 u )";
		}

		public override void Call()
		{
			var addr = Forth.Pop();
			Forth.Push(addr + 1);
			Forth.Push(Forth.Ram.GetByte(addr));
		}
	}
}